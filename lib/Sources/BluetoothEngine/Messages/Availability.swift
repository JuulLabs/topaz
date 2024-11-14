import Bluetooth
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
    let request: AvailabilityRequest

    func execute(state: BluetoothState, effector: Effector) async throws -> AvailabilityResponse {
        let result = try await effector.systemState { state in
            state != .unknown
        }
        return AvailabilityResponse(isAvailable: result.systemState.isAvailable)
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
