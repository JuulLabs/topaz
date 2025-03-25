
public enum NavigationKind: Sendable {
    /// This navigation requires launching a brand new tab
    case newWindow
    /// This navigation may continue with the existing Js context and associated BLE objects
    case sameOrigin
    /// This navigation requires a new Js context and teardown of existing BLE objects
    case crossOrigin
}
