import Bluetooth
import Helpers
import JsMessage

/**
 Main engine - keeps state, replays web API onto native API

 TODO: may need to go into it's own module
 TODO: lock this actor to the system Bluetooth DispatchQueue serial queue
 */
public actor BluetoothEngine: JsMessageProcessor {

    let client: BluetoothClient

    private var isEnabled: Bool = false
    private var systemState = DeferredValue<SystemState>()

    public init(
        client: BluetoothClient? = nil
    ) {
        self.client = client ?? .testValue
        Task {
            for await event in self.client.response.events {
                switch event {
                case let .systemState(state):
                    await systemState.setValue(state)
                    await sendEvent(.availability(isAvailable(state: state)))
                case let .disconnected(peripheral, _):
                    // TODO: deal with error case
                    await sendEvent(.disconnected(peripheral.identifier))
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
        ensureEnabled()
        switch request {
        case .getAvailability:
            let state = await systemState.getValue()
            return .availability(isAvailable(state: state))
        default:
            break
        }
        fatalError("remove me: case should be exhaustive")
    }


    // MARK: - Private helpers

    private func ensureEnabled() {
        if !isEnabled {
            isEnabled = true
            client.request.enable()
        }
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
