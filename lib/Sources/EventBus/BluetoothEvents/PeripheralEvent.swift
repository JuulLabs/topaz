import Bluetooth

public struct PeripheralEvent: BluetoothEvent {
    public let name: EventName
    public let peripheral: Peripheral

    public init(_ name: EventName, _ peripheral: Peripheral) {
        self.name = name
        self.peripheral = peripheral
    }

    public var lookup: EventLookup {
        .exact(key: .peripheral(name, peripheral))
    }
}

extension EventRegistrationKey {
    public static func peripheral(_ name: EventName, _ peripheral: Peripheral) -> Self {
        EventRegistrationKey(name: name, peripheralId: peripheral.id)
    }
}
