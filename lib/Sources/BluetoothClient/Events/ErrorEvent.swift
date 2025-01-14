import Bluetooth
import Foundation

public struct ErrorEvent: BluetoothEvent {
    public let name: EventName
    public let key: EventKey
    public let error: any Error

    public init(_ name: EventName, _ key: EventKey, _ error: any Error) {
        self.name = name
        self.key = key
        self.error = error
    }

    public init(_ name: EventName, _ peripheral: Peripheral, _ error: any Error) {
        let key = EventKey.peripheral(name, peripheral)
        self.init(name, key, error)
    }

    public init(_ name: EventName, _ peripheral: Peripheral, _ characteristic: Characteristic, _ error: any Error) {
        let key = EventKey.characteristic(name, peripheralId: peripheral.id, characteristicId: characteristic.uuid, instance: characteristic.instance)
        self.init(name, key, error)
    }

    public init(_ name: EventName, _ peripheral: Peripheral, _ characteristic: Characteristic, _ descriptor: Descriptor, _ error: any Error) {
        let key = EventKey.descriptor(name, peripheralId: peripheral.id, characteristicId: characteristic.uuid, instance: characteristic.instance, descriptorId: descriptor.uuid)
        self.init(name, key, error)
    }
}
