import Foundation

/**
 Shadows CBService
 */
public struct Service: Equatable, Sendable {
    public let uuid: UUID
    public let isPrimary: Bool

    public init(uuid: UUID, isPrimary: Bool) {
        self.uuid = uuid
        self.isPrimary = isPrimary
    }
}
