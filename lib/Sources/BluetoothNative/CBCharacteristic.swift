import Bluetooth
import CoreBluetooth
import Foundation
import Helpers

extension CBCharacteristic {
    final class InstanceStorage: AssociatedObject {
        var instance: UInt32 = 0
    }

    var instanceId: UInt32 {
        get { get(InstanceStorage.self).instance }
        set { get(InstanceStorage.self).instance = newValue }
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
