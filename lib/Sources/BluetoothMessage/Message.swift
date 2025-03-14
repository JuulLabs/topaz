import JsMessage

/**
 Models the Web Bluetooth API as Sendable data.
 https://developer.mozilla.org/en-US/docs/Web/API/Web_Bluetooth_API

 Note that all the actual Javascript objects live only within the context of a web page which is
 beyond our process boundary. Here in native-land we can only model the messaging surface. We mimic
 the API and replace parameterized objects with serializable references (e.g. UUIDs mostly).
 */
public struct Message {
    public enum Action: String, CaseIterable {
        // General
        case getAvailability
        case getDevices
        case requestDevice
        case requestLEScan

        // BluetoothDevice
        case forgetDevice
        case watchAdvertisements

        // GATT Server
        case connect
        case disconnect
        case discoverServices

        // GATT Service
        case discoverCharacteristics

        // GATT Characteristic
        case readCharacteristic
        case writeCharacteristic
        case discoverDescriptors
        case startNotifications
        case stopNotifications

        // GATT Descriptor
        case readDescriptor
    }

    public let action: Action
    private let requestBody: [String: JsType]

    public var rawRequestData: [String: JsType]? {
        requestBody["data"]?.dictionary
    }

    public init(action: Action, requestBody: [String: JsType] = [:]) {
        self.action = action
        self.requestBody = requestBody
    }

    public init(action: Action, request: JsMessageRequest) {
        self.action = action
        self.requestBody = request.body
    }

    public func decode<T: JsMessageDecodable>(_ type: T.Type) -> Result<T, Error> {
        guard let decoded = T.decode(from: rawRequestData) else {
            return .failure(MessageDecodeError.bodyDecodeFailed("\(T.self)"))
        }
        return .success(decoded)
    }
}

extension JsMessageRequest {
    public func extractMessage() -> Result<Message, any Error> {
        guard let actionString = body["action"]?.string else {
            return .failure(MessageDecodeError.badRequest)
        }
        guard let action = Message.Action.from(string: actionString) else {
            return .failure(MessageDecodeError.actionNotFound(actionString))
        }
        return .success(Message(action: action, requestBody: body))
    }
}

fileprivate extension Message.Action {
    static func from(string: String) -> Message.Action? {
        allCases.first(where: { $0.rawValue == string })
    }
}
