/// The set of operations `AppMessageProcessor` performs on behalf of the web page.
///
/// Defined here (in `AppMessage`, which only depends on `JsMessage`) so the processor stays
/// decoupled from `WebView`/`App`. A per-page conformer is supplied at construction time by the
/// composition root, which keeps the processor stateless with respect to the page and free of any
/// shared mutable wiring.
public protocol AppMessageHost: Sendable {
    /// Switches the active page's user agent. Returns `false` if the requested mode is invalid.
    func setUserAgentMode(_ mode: String) async -> Bool
}
