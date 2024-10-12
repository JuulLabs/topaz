
/**
 Shadows CBManagerState.
 */
public enum SystemState: Equatable, Sendable {
    case unknown
    case resetting
    case unsupported
    case unauthorized
    case poweredOff
    case poweredOn
}
