import Bluetooth
import Foundation
import JsMessage

struct CharacteristicChangedEvent: JsEventEncodable {
    let characteristic: Characteristic

    func toJsEvent() -> JsEvent {
        JsEvent(targetId: "<uuid>+<instance_id>", eventName: "characteristicvaluechanged")
    }
}
