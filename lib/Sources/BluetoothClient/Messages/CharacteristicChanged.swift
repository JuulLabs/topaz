import Bluetooth
import Foundation
import JsMessage

struct CharacteristicChangedEvent: JsEventEncodable {
    let peripheralId: UUID
    let characteristicUuid: UUID
    let characteristicInstance: UInt32
    let data: Data?

    func toJsEvent() -> JsEvent {
        JsEvent(targetId: characteristicKey(uuid: characteristicUuid, instance: characteristicInstance), eventName: "characteristicvaluechanged", body: data)
    }
}

fileprivate func characteristicKey(uuid: UUID, instance: UInt32) -> String {
    "\(uuid.uuidString.lowercased()).\(instance)"
}