import JsMessage

/**
 Models the Web Bluetooth API as Sendable data.
 https://developer.mozilla.org/en-US/docs/Web/API/Web_Bluetooth_API

 Note that all the actual Javascript objects live only within the context of a web page which is
 beyond our process boundary. Here in native-land we can only model the messaging surface. We mimic
 the API and replace parameterized objects with serializable references (e.g. UUIDs mostly).
 */
struct Message {
    enum Action: String, CaseIterable {
        // General
        case getAvailability
        case requestDevice

        // GATT Server
        case connect
        case disconnect
        // TODO: case getPrimaryService
        case getPrimaryServices

        // GATT Service
        // TODO: case getCharacteristic
        // TODO: case getCharacteristics

        // GATT Characteristic
        // TODO: moar descriptors, start/stop notifications, read/write value
    }

    let action: Action
    let requestBody: [String: JsType]

    init(action: Action, requestBody: [String: JsType] = [:]) {
        self.action = action
        self.requestBody = requestBody
    }

    init(action: Action, request: JsMessageRequest) {
        self.action = action
        self.requestBody = request.body
    }

    func decode<T: JsMessageDecodable>(_ type: T.Type) -> Result<T.Request, Error> {
        let data = requestBody["data"]?.dictionary
        guard let decoded = T.decode(from: data) else {
            return .failure(MessageDecodeError.bodyDecodeFailed("\(T.self)"))
        }
        return .success(decoded)
    }
}

func extractMessage(from request: JsMessageRequest) -> Result<Message, any Error> {
    guard let actionString = request.body["action"]?.string else {
        return .failure(MessageDecodeError.badRequest)
    }
    guard let action = Message.Action.from(string: actionString) else {
        return .failure(MessageDecodeError.actionNotFound(actionString))
    }
    return .success(Message(action: action, requestBody: request.body))
}

extension Message.Action {
    static func from(string: String) -> Message.Action? {
        allCases.first(where: { $0.rawValue == string })
    }
}
