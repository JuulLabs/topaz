import Bluetooth
import JsMessage

extension BluetoothError {
    var asJsResponse: JsMessageResponse {
        .error(localizedDescription)
    }
}
