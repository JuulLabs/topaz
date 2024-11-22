import Bluetooth
import CoreBluetooth
import Helpers

extension CBService {
    func erase(locker: any LockingStrategy) -> Service {
        Service(
            service: AnyProtectedObject(wrapping: self, in: locker),
            uuid: self.uuid.regularUuid,
            isPrimary: self.isPrimary
        )
    }
}

extension Service {
    var rawValue: CBService? {
        service.wrapped.unsafeObject as? CBService
    }
}
