
/**
 Models the various CoreBluetooth delegate events as Sendable data.
 */
public enum DelegateEvent: Equatable, Sendable {
    case systemState(SystemState)
    case advertisement(AnyPeripheral, Advertisement)
    case connected(AnyPeripheral)
    case disconnected(AnyPeripheral, DelegateEventError?)
    case discoveredServices(AnyPeripheral, DelegateEventError?)
    case discoveredCharacteristics(AnyPeripheral, Service, DelegateEventError?)
    case updatedCharacteristic(AnyPeripheral, Characteristic, DelegateEventError?)
}

public enum DelegateEventError: Error, Sendable {
    case causedBy(any Error)
}

extension DelegateEventError: Equatable {
    public static func == (lhs: DelegateEventError, rhs: DelegateEventError) -> Bool {
        switch (lhs, rhs) {
        case let (.causedBy(lhsError), .causedBy(rhsError)):
            // This only makes sense because the underlying NSErrors are equatable
            _isEqual(lhsError, rhsError) ?? false
        }
    }
}
