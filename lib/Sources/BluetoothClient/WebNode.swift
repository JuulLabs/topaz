
public typealias WebNodeIdentifier = Int

/**
 Represents the communications channel to a web page javascript context.
 */
public struct WebNode: Sendable, Identifiable {
    public let id: WebNodeIdentifier
    public let sendEvent: @MainActor @Sendable (_ event: WebBluetoothEvent) -> Void

    public init(
        id: WebNodeIdentifier,
        sendEvent: @MainActor @Sendable @escaping (_ event: WebBluetoothEvent) -> Void
    ) {
        self.id = id
        self.sendEvent = sendEvent
    }
}
