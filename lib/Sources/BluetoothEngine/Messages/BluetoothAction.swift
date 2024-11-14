import Bluetooth
import BluetoothClient
import DevicePicker
import Effector
import JsMessage

protocol BluetoothAction: Sendable {
    associatedtype Request: Sendable, JsMessageDecodable
    associatedtype Response: Sendable, JsMessageEncodable

    init(request: Request)

    func execute(state: BluetoothState, effector: Effector) async throws -> Response
}

extension BluetoothAction {
    static func create(from message: Message) -> Result<any BluetoothAction, Error> {
        Request.decode(from: message).map(Self.init)
    }
}

extension Message {
    func buildAction(selector: any InteractiveDeviceSelector, client: RequestClient) -> Result<any BluetoothAction, Error> {
        switch action {
        case .getAvailability:
            return Availability.create(from: self)
        case .requestDevice:
            return RequestDeviceRequest.decode(from: self).map {
                RequestDevice(request: $0, selector: selector, client: client)
            }
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
