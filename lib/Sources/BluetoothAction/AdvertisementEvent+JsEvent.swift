import Bluetooth
import BluetoothClient
import Foundation
import JsMessage

extension AdvertisementEvent {
    func toJs() -> JsEvent {
        // https://webbluetoothcg.github.io/web-bluetooth/#advertising-events
        let jsAdvertisement: [String: JsConvertable] = [
            "uuids": peripheral.services.map { $0.uuid },
            "name": advertisement.localName ?? jsNull,
            "rssi": advertisement.rssi,
            "txPower": advertisement.txPowerLevel ?? jsNull,
            "manufacturerData": advertisement.manufacturerData?.asJsDictionary(),
            "serviceData": advertisement.serviceData.asJsDictionary(),
        ]
        let jsDevice: [String: JsConvertable] = [
            "uuid": peripheral.id,
            "name": peripheral.name ?? jsNull,
        ]
        let body: [String: JsConvertable] = [
            "advertisement": jsAdvertisement,
            "device": jsDevice,
        ]
        return JsEvent(targetId: "bluetooth", eventName: "advertisementreceived", body: body)
    }
}

extension ManufacturerData {
    func asJsDictionary() -> [String: JsConvertable] {
        ["code": code, "data": data]
    }
}

extension ServiceData {
    func asJsDictionary() -> [String: JsConvertable] {
        rawData.reduce(into: [:]) { dict, item in
            dict[item.key.uuidString.lowercased()] = item.value
        }
    }
}
