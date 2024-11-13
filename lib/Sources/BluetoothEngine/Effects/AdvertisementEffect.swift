import Bluetooth
import Foundation

public struct AdvertisementEffect: BluetoothEffect {
    public let peripheral: AnyPeripheral
    public let advertisement: Advertisement

    public init(_ peripheral: AnyPeripheral, _ advertisement: Advertisement) {
        self.peripheral = peripheral
        self.advertisement = advertisement
    }

    public var key: EffectKey {
        .advertisement
    }
}

extension EffectKey {
    static let advertisement = EffectKey(name: .advertisement)
}
