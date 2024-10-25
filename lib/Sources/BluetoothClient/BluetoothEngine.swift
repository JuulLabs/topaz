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
                switch event {
                case let .systemState(state):
                    await systemState.setValue(state)
                    await sendEvent(.availability(isAvailable(state: state)))
                case let .disconnected(peripheral, _):
                    // TODO: deal with error case
                    await sendEvent(.disconnected(peripheral.identifier))
                case let .advertisement(peripheral, advertisement):
                    await deviceSelector.showAdvertisement(peripheral: peripheral, advertisement: advertisement)
                default:
                    break
                }
            }
        }
    }


    // MARK: - JsMessageProcessor
    public let handlerName: String = "bluetooth"
    private var context: JsContext?

    public func didAttach(to context: JsContext) async {
        self.context = context
    }

    private func sendEvent(_ event: WebBluetoothEvent) async {
        await context?.eventSink.send(event.toJsEvent())
    }

    public func process(request: JsMessageRequest) async -> JsMessageResponse {
        guard let request = WebBluetoothRequest.decode(from: request) else {
            return .error("Bad request")
        }
        return await self.process(request: request).encode()
    }

    func process(request: WebBluetoothRequest) async -> WebBluetoothResponse {
        switch request {
        case .getAvailability:
            return await currentAvailablility()
        case let .requestDevice(filter):
            return await bluetoothReady {
                await obtainDeviceViaPicker(filter: filter)
            }
        default:
            break
        }
        fatalError("remove me: case should be exhaustive")
    }


    // MARK: - Private helpers

    private func obtainDeviceViaPicker(filter: Filter) async -> WebBluetoothResponse {
        client.request.startScanning(filter)
        defer { client.request.stopScanning() }
        switch await deviceSelector.awaitSelection() {
        case let .success(peripheral):
            peripherals[peripheral.identifier] = peripheral
            return .device(peripheral.identifier, peripheral.name)
        case let .failure(error):
            return .error(error)
        }
    }

    private func currentAvailablility() async -> WebBluetoothResponse {
        repeat {
            guard let state = await waitForLatestState(), !Task.isCancelled else {
                // Cancelled - means the web page got torn down
                return .availability(isAvailable(state: .unknown))
            }
            switch state {
            case .unknown:
                // Keep waiting
                break
            default:
                return .availability(isAvailable(state: state))
            }
        } while true
    }

    /// Blocks until we are in powered on state before running the operation
    /// Returns an error if the state is not powered on
    private func bluetoothReady(_ block: () async -> WebBluetoothResponse) async -> WebBluetoothResponse {
        var isPoweredOn = false
        repeat {
            guard let state = await waitForLatestState(), !Task.isCancelled else {
                // Cancelled - means the web page got torn down
                return .error(BluetoothError.unknown)
            }
            switch state {
            case .poweredOn:
                isPoweredOn = true
            case .unsupported, .unauthorized, .poweredOff:
                return .error(BluetoothError.unavailable)
            case .unknown, .resetting:
                // Keep waiting
                break
            }
        } while !isPoweredOn
        return await block()
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
