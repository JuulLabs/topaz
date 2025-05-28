import Bluetooth

public struct SystemStateEvent: BluetoothEvent {
    public let systemState: SystemState

    public init(_ systemState: SystemState) {
        self.systemState = systemState
    }

    public let lookup: EventLookup = .exact(key: .systemState)
}

extension EventRegistrationKey {
    public static let systemState = EventRegistrationKey(name: .systemState)
}
