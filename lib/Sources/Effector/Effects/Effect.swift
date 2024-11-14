import Bluetooth
import Foundation

public protocol Effect: Sendable {
    var key: EffectKey { get }
}
