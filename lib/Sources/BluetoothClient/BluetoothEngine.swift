import Bluetooth

/**
 Main engine - keeps state, replays web API onto native API

 TODO: may need to go into it's own module
 TODO: lock this actor to the system Bluetooth DispatchQueue serial queue
 */
public actor BluetoothEngine {

    let client: BluetoothClient // TODO: from dependencies

    private lazy var initialSystemState: SystemState = client.request.enable()

    public init(
        client: BluetoothClient? = nil
    ) {
        self.client = client ?? .poweredOnMock
    }

    public func perform(action: WebBluetoothRequest, for node: WebNode) {
        fatalError("Not implemented")
    }

    public func process(request: WebBluetoothRequest, for node: WebNode) async -> WebBluetoothResponse {
        switch request {
        case .getAvailability:
            .availability(isAvailable())
        default:
            fatalError("remove me: case should be exhaustive")
        }
    }

    private func isAvailable() -> Bool {
        switch initialSystemState {
        case .unknown, .unsupported, .unauthorized, .poweredOff:
            false
        case .resetting, .poweredOn:
            true
        }
    }
}

// Hack just to get things rolling
extension BluetoothClient {
    nonisolated(unsafe) static var poweredOnMock: Self = {
        var requestClient = RequestClient.testValue
        requestClient.enable = { .poweredOn }
        var responseClient = ResponseClient.testValue
        responseClient.events = AsyncStream<DelegateEvent> { continuation in
            continuation.yield(.systemState(.poweredOn))
        }
        return BluetoothClient(request: requestClient, response: responseClient)
    }()
}
