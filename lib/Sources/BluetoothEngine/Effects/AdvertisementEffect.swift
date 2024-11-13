import Bluetooth
import Foundation

struct AdvertisementEffect: BluetoothEffect {
    let peripheral: AnyPeripheral
    let advertisement: Advertisement

    init(_ peripheral: AnyPeripheral, _ advertisement: Advertisement) {
        self.peripheral = peripheral
        self.advertisement = advertisement
    }

    var key: EffectKey {
        .advertisement
    }
}

extension EffectKey {
    static let advertisement = EffectKey(name: .advertisement)
}
