import Bluetooth
import DevicePicker
import Foundation
import Helpers
import JsMessage

/**
 Main engine - keeps state, replays web API onto native API

 TODO: may need to go into it's own module
 TODO: lock this actor to the system Bluetooth DispatchQueue serial queue
 */
public actor BluetoothEngine: JsMessageProcessor {

    private var isEnabled: Bool = false
    private var systemState = DeferredValue<SystemState>()
    private var peripherals: [UUID: AnyPeripheral] = [:]

    public let deviceSelector: InteractiveDeviceSelector
    public let client: BluetoothClient

    public init(
        deviceSelector: InteractiveDeviceSelector,
        client: BluetoothClient
    ) {
        self.client = client
        self.deviceSelector = deviceSelector
        Task {
            for await event in self.client.response.events {
                await handleDelegateEvent(event)
            }
        }
    }


    // MARK: - Bluetooth Delegate Events

    private func handleDelegateEvent(_ event: DelegateEvent) async {
        switch event {
        case let .systemState(state):
            await systemState.setValue(state)
            await sendEvent(AvailabilityEvent(isAvailable: isAvailable(state: state)))
        case let .advertisement(peripheral, advertisement):
            await deviceSelector.showAdvertisement(peripheral: peripheral, advertisement: advertisement)
        case let .connected(peripheral):
            resolveAction(.connect, for: peripheral.identifier)
        case let .disconnected(peripheral, error):
            resolveAction(.disconnect, for: peripheral.identifier, with: error)
            await sendEvent(DisconnectEvent(peripheralId: peripheral.identifier))
        case let .discoveredServices(peripheral, error):
            resolveAction(.discoverServices, for: peripheral.identifier, with: error)
        case let .discoveredCharacteristics(peripheral, _, error):
            resolveAction(.discoverCharacteristics, for: peripheral.identifier, with: error)
        case let .characteristicChanged(peripheral, characteristic):
            await sendEvent(CharacteristicChangedEvent(characteristic: characteristic))
        case .updatedCharacteristic:
            fatalError("not implemented")
        }
    }

    // MARK: - JsMessageProcessor
    public let handlerName: String = "bluetooth"
    private var context: JsContext?
    private var promiseRegistry: PromiseRegistry?

    public func didAttach(to context: JsContext) async {
        self.context = context
        promiseRegistry = PromiseRegistry()
    }

    public func didDetach(from context: JsContext) async {
        promiseRegistry?.rejectAll(with: BluetoothError.cancelled)
        promiseRegistry = nil
        self.context = nil
    }

    private func sendEvent(_ event: JsEventEncodable) async {
        await context?.sendEvent(event.toJsEvent())
    }

    public func process(request: JsMessageRequest) async -> JsMessageResponse {
        do {
            let message = try extractMessage(from: request).get()
            return try await process(message: message).toJsMessage()
        } catch {
            return .error(error.toDomError())
        }
    }

    func process(message: Message) async throws -> JsMessageEncodable {
        switch message.action {
        // General Operations
        case .getAvailability: await getAvailability()
        case .requestDevice: try await requestDevice(message: message)

        // GATT Server
        case .connect: try await connect(message: message)
        case .disconnect: try await disconnect(message: message)
        case .discoverServices: try await discoverServices(message: message)

        // GATT Service
        case .discoverCharacteristics: try await discoverCharacteristics(message: message)

        // GATT Characteristic
        // TODO: moar descriptors, start/stop notifications, read/write value
        }
    }

    // MARK: - Bluetooth General Operations

    private func getAvailability() async -> GetAvailabilityResponse {
        repeat {
            guard let state = await waitForLatestState(), !Task.isCancelled else {
                // Cancelled - means the web page got torn down
                return GetAvailabilityResponse(isAvailable: isAvailable(state: .unknown))
            }
            switch state {
            case .unknown:
                // Keep waiting
                break
            default:
                return GetAvailabilityResponse(isAvailable: isAvailable(state: state))
            }
        } while true // TODO: timeout
    }

    private func requestDevice(message: Message) async throws -> RequestDeviceResponse {
        let data = try RequestDeviceRequest.decode(from: message).get()
        try await bluetoothReadyState()
        client.request.startScanning(data.filter)
        defer { client.request.stopScanning() }
        let peripheral = try await deviceSelector.awaitSelection().get()
        addPeripheral(peripheral)
        return RequestDeviceResponse(peripheralId: peripheral.identifier, name: peripheral.name)
    }

    // MARK: - Bluetooth GATT Server

    private func connect(message: Message) async throws -> ConnectResponse {
        let data = try ConnectRequest.decode(from: message).get()
        try await bluetoothReadyState()
        let peripheral = try getPeripheral(data.peripheralId)
        if case .connected = peripheral.connectionState {
            return ConnectResponse()
        }
        try await awaitAction(action: message.action, uuid: peripheral.identifier) {
            client.request.connect(peripheral)
        }
        return ConnectResponse()
    }

    private func disconnect(message: Message) async throws -> DisconnectResponse {
        let data = try DisconnectRequest.decode(from: message).get()
        try await bluetoothReadyState()
        let peripheral = try getPeripheral(data.peripheralId)
        if case .disconnected = peripheral.connectionState {
            return DisconnectResponse(peripheralId: peripheral.identifier)
        }
        try await awaitAction(action: message.action, uuid: peripheral.identifier) {
            client.request.disconnect(peripheral)
        }
        return DisconnectResponse(peripheralId: peripheral.identifier)
    }

    private func discoverServices(message: Message) async throws -> DiscoverServicesResponse {
        let data = try DiscoverServicesRequest.decode(from: message).get()
        try await bluetoothReadyState()
        let peripheral = try getPeripheral(data.peripheralId)
        // todo: error response if not connected
        try await awaitAction(action: message.action, uuid: peripheral.identifier) {
            client.request.discoverServices(peripheral, data.toServiceDiscoveryFilter())
        }
        let primaryServices = peripherals[peripheral.identifier]?.services.filter { $0.isPrimary } ?? []
        switch data.query {
        case let .first(serviceUuid):
            guard let service = primaryServices.first else {
                throw BluetoothError.noSuchService(serviceUuid)
            }
            return DiscoverServicesResponse(peripheralId: peripheral.identifier, services: [service])
        case .all:
            return DiscoverServicesResponse(peripheralId: peripheral.identifier, services: primaryServices)
        }
    }

    private func discoverCharacteristics(message: Message) async throws -> DiscoverCharacteristicsResponse {
        let data = try DiscoverCharacteristicsRequest.decode(from: message).get()
        try await bluetoothReadyState()
        let peripheral = try getPeripheral(data.peripheralId)
        // todo: error response if not connected
        try await awaitAction(action: message.action, uuid: peripheral.identifier) {
            client.request.discoverCharacteristics(peripheral, data.toCharacteristicDiscoveryFilter())
        }
        let characteristics = peripherals[peripheral.identifier]?.services.first(where: { $0.uuid == data.serviceUuid })?.characteristics ?? []
        switch data.query {
        case let .first(characteristicUuid):
            guard let characteristic = characteristics.first else {
                throw BluetoothError.noSuchCharacteristic(service: data.serviceUuid, characteristic: characteristicUuid)
            }
            return DiscoverCharacteristicsResponse(peripheralId: peripheral.identifier, characteristics: [characteristic])
        case .all:
            return DiscoverCharacteristicsResponse(peripheralId: peripheral.identifier, characteristics: characteristics)
        }
    }

    private func startCharacteristicNotifications(message: Message) async throws -> StartCharacteristicNotificationsResponse {
        // todo
    }
    
    private func stopCharacteristicNotifications(message: Message) async throws -> StopCharacteristicNotificationsResponse {
        // todo
    }

    // MARK: - Private helpers

    private func resolveAction(_ action: Message.Action, for id: UUID, with error: (any Error)? = nil) {
        promiseRegistry?.resolve(action, for: id, with: error)
    }

    private func awaitAction(
        action: Message.Action,
        uuid: UUID,
        launchEffect: () -> Void
    ) async throws {
        guard let promise = promiseRegistry?.register(action, for: uuid) else {
            throw BluetoothError.unavailable
        }
        launchEffect()
        try await promise.awaitResolved()
    }

    /// Marked internal for testing purposes
    internal func addPeripheral(_ peripheral: AnyPeripheral) {
        peripherals[peripheral.identifier] = peripheral
    }

    /// Marked internal for testing purposes
    internal func getPeripheral(_ uuid: UUID) throws -> AnyPeripheral {
        guard let peripheral = peripherals[uuid] else {
            throw BluetoothError.noSuchDevice(uuid)
        }
        return peripheral
    }

    /// Blocks until we are in powered on state
    /// Throws an error if the state is not powered on
    private func bluetoothReadyState() async throws {
        var isPoweredOn = false
        repeat {
            guard let state = await waitForLatestState(), !Task.isCancelled else {
                // Cancelled - means the web page got torn down
                throw BluetoothError.unknown
            }
            switch state {
            case .poweredOn:
                isPoweredOn = true
            case .unsupported, .unauthorized, .poweredOff:
                throw BluetoothError.unavailable
            case .unknown, .resetting:
                // Keep waiting
                break
            }
        } while !isPoweredOn
    }

    private func waitForLatestState() async -> SystemState? {
        if !isEnabled {
            isEnabled = true
            client.request.enable()
        }
        return await systemState.getValue()
    }

    private func isAvailable(state: SystemState?) -> Bool {
        guard let state else { return false }
        return switch state {
        case .unknown, .unsupported, .unauthorized, .poweredOff:
            false
        case .resetting, .poweredOn:
            true
        }
    }
}

fileprivate extension DiscoverServicesRequest {
    func toServiceDiscoveryFilter() -> ServiceDiscoveryFilter {
        let services = query.serviceUuid.map { [$0] }
        return ServiceDiscoveryFilter(primaryOnly: true, services: services)
    }
}

fileprivate extension DiscoverCharacteristicsRequest {
    func toCharacteristicDiscoveryFilter() -> CharacteristicDiscoveryFilter {
        let characteristics = query.characteristicUuid.map { [$0] }
        return CharacteristicDiscoveryFilter(service: serviceUuid, characteristics: characteristics)
    }
}
