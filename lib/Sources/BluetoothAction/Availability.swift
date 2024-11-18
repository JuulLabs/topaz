import Bluetooth
import BluetoothClient
import BluetoothMessage
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

extension SystemStateEvent {
    public func availabilityChangedEvent() -> JsEvent {
        JsEvent(targetId: "bluetooth", eventName: "availabilitychanged", body: systemState.isAvailable)
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
