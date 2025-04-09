import Bluetooth
import Observation

/**
 This class is declared as a singleton that exposes the active bluetooth system state
 for use by the UI layer. Any instance of the BluetoothEngine that is attached to
 a WebView and actively executing Bluetooth operations may update the global value.
 */
@MainActor
@Observable
public final class BluetoothSystemState {
    public private(set) var systemState: SystemState

    public init(systemState: SystemState = .unknown) {
        self.systemState = systemState
    }

    public func updateSystemState(_ newValue: SystemState) {
        guard newValue != .unknown else { return }
        self.systemState = newValue
    }
}

public extension BluetoothSystemState {
    static let shared = BluetoothSystemState()
}
