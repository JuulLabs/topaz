
/**
 Shadows CBPeripheralState.
 */
public enum ConnectionState: Equatable, Sendable {
    case connected
    case disconnected
    // Do we need these to fulfil the Web APIs?
    // case connecting
    // case disconnecting
    // case unknown
}
