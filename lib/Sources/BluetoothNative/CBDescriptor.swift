import Bluetooth
import CoreBluetooth
import Helpers

extension CBDescriptor {
    func erase(locker: any LockingStrategy) -> Descriptor {
        let wrappedValue: Descriptor.Value = self.value.map { anyValue in
            switch anyValue {
            case let number as NSNumber:
                    .number(number)
            case let string as NSString:
                    .string(string as String)
            case let data as NSData:
                    .data(data as Data)
            default:
                    .none
            }
        } ?? .none
        return Descriptor(
            descriptor: AnyProtectedObject(wrapping: self, in: locker),
            uuid: self.uuid.regularUuid,
            value: wrappedValue
        )
    }
}

extension Descriptor {
    var rawValue: CBDescriptor? {
        descriptor.wrapped.unsafeObject as? CBDescriptor
    }
}
