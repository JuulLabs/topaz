import Foundation
import Helpers

/**
 Shadows CBService
 */
public struct Service: Equatable, Sendable {
    public let service: AnyProtectedObject
    public let uuid: UUID
    public let isPrimary: Bool
    public var characteristics: [Characteristic]

    public init(
        service: AnyProtectedObject,
        uuid: UUID,
        isPrimary: Bool,
        characteristics: [Characteristic] = []
    ) {
        self.service = service
        self.uuid = uuid
        self.isPrimary = isPrimary
        self.characteristics = characteristics
    }
}
