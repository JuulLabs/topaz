import Foundation

/**
 Shadows CBDescriptor
 */
public struct Descriptor: Equatable, Sendable {
    public let uuid: UUID
    public let value: Value

    public enum Value: Equatable, Sendable {
        case number(NSNumber)
        case string(String)
        case data(Data)
        case none
    }

    public init(uuid: UUID, value: Value) {
        self.uuid = uuid
        self.value = value
    }
}

