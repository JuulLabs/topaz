#if targetEnvironment(simulator)
import SwiftUI

/// Runs a block (blocking on main thread) before the view renders
private struct PreRenderLoader<T>: View where T: View {

    private var content: T

    init(_ closure: () -> Void, content: T) {
        closure()
        self.content = content
    }

    var body: some View {
        content
    }
}

extension View {
    public func forceLoadFontsInPreview() -> some View {
        PreRenderLoader(
            { registerFonts() },
            content: self
        )
    }
}
#endif
