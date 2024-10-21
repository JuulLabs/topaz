import Bluetooth
import Helpers

/**
 Main engine - keeps state, replays web API onto native API

 TODO: may need to go into it's own module
 TODO: lock this actor to the system Bluetooth DispatchQueue serial queue
 */
public actor BluetoothEngine {

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
                default:
                    break
                }
            }
        }
    }

    public func perform(action: WebBluetoothRequest, for node: WebNode) {
        fatalError("Not implemented")
    }

    public func process(request: WebBluetoothRequest, for node: WebNode) async -> WebBluetoothResponse {
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
