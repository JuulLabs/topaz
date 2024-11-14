import Bluetooth
import Foundation

public struct PeripheralEvent: DelEvent {
    let name: EventName

    public let peripheral: AnyPeripheral

    public init(_ name: EventName, _ peripheral: AnyPeripheral) {
        self.name = name
        self.peripheral = peripheral
    }

    public var key: EventKey {
        .peripheral(name, peripheral)
    }
}

extension EventKey {
    static func peripheral(_ name: EventName, _ peripheral: AnyPeripheral) -> Self {
        EventKey(name: name, peripheral.identifier)
    }
}
