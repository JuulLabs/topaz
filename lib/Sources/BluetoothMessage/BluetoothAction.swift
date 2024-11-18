import Bluetooth
import BluetoothClient
import DevicePicker
import JsMessage

/**
 Models interaction with the Web BLE promise based APIs.
 */
public protocol BluetoothAction: Sendable {
    associatedtype Request: Sendable, JsMessageDecodable
    associatedtype Response: Sendable, JsMessageEncodable

    var requiresReadyState: Bool { get }

    init(request: Request)

    func execute(state: BluetoothState, client: BluetoothClient) async throws -> Response
}

extension BluetoothAction {
    public static func create(from message: Message) -> Result<any BluetoothAction, Error> {
        Request.decode(from: message).map(Self.init)
    }
}
