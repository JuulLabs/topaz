import Bluetooth
import Foundation

public struct ResponseClient: Sendable {
    public var events: AsyncStream<DelegateEvent>

    public init(events: AsyncStream<DelegateEvent>) {
        self.events = events
    }
}

extension ResponseClient {
    public static let testValue = ResponseClient(
        events: AsyncStream { _ in
            fatalError("Not implemented")
        }
    )
}
