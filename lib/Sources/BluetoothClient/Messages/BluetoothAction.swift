import Bluetooth
import JsMessage

protocol BluetoothAction: Sendable {
    associatedtype Request: Sendable, JsMessageDecodable
    associatedtype Response: Sendable, JsMessageEncodable

    init(request: Request)

    func execute(state: BluetoothState, effector: some BluetoothEffector) async throws -> Response
}

extension BluetoothAction {
    static func create(from message: Message) -> Result<any BluetoothAction, Error> {
        Request.decode(from: message).map(Self.init)
    }
}

extension Message {
    func buildAction() -> Result<any BluetoothAction, Error> {
        switch action {
        case .getAvailability:
            fatalError()
        case .requestDevice:
            fatalError()
        case .connect:
            return Connector.create(from: self)
        case .disconnect:
            return Disconnector.create(from: self)
        case .discoverServices:
            return DiscoverServices.create(from: self)
        case .discoverCharacteristics:
            return DiscoverCharacteristics.create(from: self)
        }
    }
}
