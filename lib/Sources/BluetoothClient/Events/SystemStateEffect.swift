import Bluetooth

public struct SystemStateEvent: DelEvent {
    public let systemState: SystemState

    public init(_ systemState: SystemState) {
        self.systemState = systemState
    }

    public var key: EventKey {
        .systemState
    }
}

extension EventKey {
    static let systemState = EventKey(name: .systemState)
}
