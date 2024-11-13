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

    private let state: BluetoothState

    public let deviceSelector: InteractiveDeviceSelector
    public let client: BluetoothClient

    public init(
        state: BluetoothState,
        deviceSelector: InteractiveDeviceSelector,
        client: BluetoothClient
    ) {
        self.state = state
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
        case .connect: try await processAction(message: message)
        case .disconnect: try await processAction(message: message)
        case .discoverServices: try await processAction(message: message)

        // GATT Service
        case .discoverCharacteristics: try await processAction(message: message)

        // GATT Characteristic
        // TODO: moar descriptors, start/stop notifications, read/write value
        }
    }

    private func processAction(message: Message) async throws -> JsMessageEncodable {
        let action = try message.buildAction().get()
        return try await action.execute(state: state, effector: self)
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
        await state.putPeripheral(peripheral)
        return RequestDeviceResponse(peripheralId: peripheral.identifier, name: peripheral.name)
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

    /// Blocks until we are in powered on state
    /// Throws an error if the state is not powered on
    func bluetoothReadyState() async throws {
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

extension BluetoothEngine: BluetoothEffector {
    func runEffect(action: Message.Action, uuid: UUID, effect: @Sendable (RequestClient) -> Void) async throws {
        guard let promise = promiseRegistry?.register(action, for: uuid) else {
            throw BluetoothError.unavailable
        }
        effect(client.request)
        try await promise.awaitResolved()
    }
}
