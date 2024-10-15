
public enum BluetoothError: Error, Sendable {
    case CausedBy(any Error)
    case Unknown
}

extension BluetoothError: Equatable {
    public static func == (lhs: BluetoothError, rhs: BluetoothError) -> Bool {
        switch (lhs, rhs) {
        case let (.CausedBy(lhsError), .CausedBy(rhsError)):
            // This only makes sense because the underlying NSErrors are equatable
            _isEqual(lhsError, rhsError) ?? false
        case (.Unknown, .Unknown):
            true
        default:
            false
        }
    }
}
