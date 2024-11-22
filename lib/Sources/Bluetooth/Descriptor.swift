import Foundation
import Helpers

/**
 Shadows CBDescriptor
 */
public struct Descriptor: Equatable, Sendable {
    public let descriptor: AnyProtectedObject
    public let uuid: UUID
    public let value: Value

    public enum Value: Equatable, Sendable {
        case number(NSNumber)
        case string(String)
        case data(Data)
        case none
    }

    public init(descriptor: AnyProtectedObject, uuid: UUID, value: Value) {
        self.descriptor = descriptor
        self.uuid = uuid
        self.value = value
    }
}
