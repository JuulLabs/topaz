import Bluetooth
import Foundation

public struct ResponseClient: Sendable {
    public var events: AsyncStream<DelegateEvent>
    public var effects: AsyncStream<DelEvent>

    public init(events: AsyncStream<DelegateEvent>, effects: AsyncStream<DelEvent>) {
        self.events = events
        self.effects = effects
    }
}

extension ResponseClient {
    public static let testValue = ResponseClient(
        events: AsyncStream { _ in
        },
        effects: AsyncStream { _ in
        }
    )
}
