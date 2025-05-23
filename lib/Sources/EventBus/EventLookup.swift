import Foundation

/**
 Event indexing mechanism for locating a previously registered event when it comes time to resolve its promise.
 */
public struct EventLookup: Sendable {
    public enum Match: Sendable {
        case exact(EventRegistrationKey)
        case wildcard(EventName?, EventAttributes)
    }

    public let match: Match

    public init(match: Match) {
        self.match = match
    }

    public static func exact(key: EventRegistrationKey) -> Self {
        Self(match: .exact(key))
    }

    public static func exact(
        name: EventName,
        peripheralId: UUID? = nil,
        serviceId: UUID? = nil,
        characteristicId: UUID? = nil,
        characteristicInstance: UInt32? = nil,
        descriptorId: UUID? = nil
    ) -> Self {
        let key = EventRegistrationKey(
            name: name,
            peripheralId: peripheralId,
            serviceId: serviceId,
            characteristicId: characteristicId,
            characteristicInstance: characteristicInstance,
            descriptorId: descriptorId
        )
        return Self(match: .exact(key))
    }

    public static func wildcard(
        name: EventName? = nil,
        peripheralId: UUID? = nil,
        serviceId: UUID? = nil,
        characteristicId: UUID? = nil,
        characteristicInstance: UInt32? = nil,
        descriptorId: UUID? = nil
    ) -> Self {
        let attributes = EventAttributes(
            peripheralId: peripheralId,
            serviceId: serviceId,
            characteristicId: characteristicId,
            characteristicInstance: characteristicInstance,
            descriptorId: descriptorId
        )
        return Self(match: .wildcard(name, attributes))
    }
}

public extension EventAttributes {
    func predicate(name: EventName? = nil) -> @Sendable (EventRegistrationKey) -> Bool {
        return { [lhs = self] key in
            let rhs = key.attributes
            guard name == nil || name == key.name else { return false }
            guard lhs.peripheralId == nil || lhs.peripheralId == rhs.peripheralId else { return false }
            guard lhs.serviceId == nil || lhs.serviceId == rhs.serviceId else { return false }
            guard lhs.characteristicId == nil || lhs.characteristicId == rhs.characteristicId else { return false }
            guard lhs.characteristicInstance == nil || lhs.characteristicInstance == rhs.characteristicInstance else { return false }
            guard lhs.descriptorId == nil || lhs.descriptorId == rhs.descriptorId else { return false }
            return true
        }
    }
}
