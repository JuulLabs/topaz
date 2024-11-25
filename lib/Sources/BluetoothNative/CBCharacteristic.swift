import Bluetooth
import CoreBluetooth
import Foundation
import Helpers

extension CBCharacteristic {
    var instanceId: UInt32 {
        UInt32(truncatingIfNeeded: ObjectIdentifier(self).hashValue)
    }
}

extension CBCharacteristic {
    func erase(locker: any LockingStrategy) -> Characteristic {
        Characteristic(
            characteristic: AnyProtectedObject(wrapping: self, in: locker),
            uuid: self.uuid.regularUuid,
            instance: self.instanceId,
            properties: CharacteristicProperties(rawValue: self.properties.rawValue),
            value: self.value,
            isNotifying: self.isNotifying
        )
    }
}

extension Characteristic {
    var rawValue: CBCharacteristic? {
        characteristic.wrapped.unsafeObject as? CBCharacteristic
    }
}
