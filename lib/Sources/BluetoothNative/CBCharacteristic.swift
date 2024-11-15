import CoreBluetooth
import Foundation

extension CBCharacteristic {
    var instanceId: UInt32 {
        UInt32(truncatingIfNeeded: ObjectIdentifier(self).hashValue)
    }
}
