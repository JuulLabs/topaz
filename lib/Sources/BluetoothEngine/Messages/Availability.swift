import Bluetooth
import BluetoothClient
import Effector
import JsMessage

struct AvailabilityRequest: JsMessageDecodable {
    static func decode(from data: [String: JsType]?) -> Self? {
        return .init()
    }
}

struct AvailabilityResponse: JsMessageEncodable {
    let isAvailable: Bool

    func toJsMessage() -> JsMessage.JsMessageResponse {
        .body(["isAvailable": isAvailable])
    }
}

struct AvailabilityEvent: JsEventEncodable {
    let isAvailable: Bool

    init(isAvailable: Bool) {
        self.isAvailable = isAvailable
    }

    init(state: SystemState) {
        self.init(isAvailable: state.isAvailable)
    }

    func toJsEvent() -> JsEvent {
        JsEvent(targetId: "bluetooth", eventName: "availabilitychanged", body: isAvailable)
    }
}

struct Availability: BluetoothAction {
    let requiresReadyState: Bool = false
    let request: AvailabilityRequest

    func execute(state: BluetoothState, client: BluetoothClient) async throws -> AvailabilityResponse {
        let currentState = await state.systemState
        guard currentState != .unknown else {
            let result = try await client.awaitSystemState { state in
                state != .unknown
            }
            return AvailabilityResponse(isAvailable: result.isAvailable)
        }
        return AvailabilityResponse(isAvailable: currentState.isAvailable)
    }

}

fileprivate extension SystemState {
    var isAvailable: Bool {
        return switch self {
        case .unknown, .unsupported, .unauthorized, .poweredOff:
            false
        case .resetting, .poweredOn:
            true
        }
    }
}
