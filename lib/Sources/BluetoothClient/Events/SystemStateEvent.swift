import Bluetooth

public struct SystemStateEvent: BluetoothEvent {
    public let name: EventName = .systemState
    public let systemState: SystemState

    public init(_ systemState: SystemState) {
        self.systemState = systemState
    }

    public var key: EventKey {
        .systemState
    }
}

extension EventKey {
    public static let systemState = EventKey(name: .systemState)
}
