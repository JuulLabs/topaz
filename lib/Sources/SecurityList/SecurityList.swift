import Foundation

public struct SecurityList: Sendable {
    public enum Operation: Sendable, CaseIterable {
        case reading, writing, any
    }

    public enum Group: Sendable, CaseIterable {
        case services, characteristics, descriptors
    }

    private let services: [UUID: Operation]
    private let characteristics: [UUID: Operation]
    private let descriptors: [UUID: Operation]

    public init(
        services: [UUID: Operation] = [:],
        characteristics: [UUID: Operation] = [:],
        descriptors: [UUID: Operation] = [:]
    ) {
        self.services = services
        self.characteristics = characteristics
        self.descriptors = descriptors
    }

    public func isBlocked(_ uuid: UUID, in group: Group, for operation: Operation = .any) -> Bool {
        let exclusion = switch group {
        case .services: services[uuid]
        case .characteristics: characteristics[uuid]
        case .descriptors: descriptors[uuid]
        }
        guard let exclusion else {
            return false
        }
        return exclusion == .any || operation == .any || exclusion == operation
    }
}
