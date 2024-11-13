import Bluetooth
import Foundation

protocol BluetoothEffect: Sendable {
    var key: EffectKey { get }
}
