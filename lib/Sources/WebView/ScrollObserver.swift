import UIHelpers
import UIKit
import VirtualKeyboard
import WebKit

@MainActor
final class ScrollObserver: NSObject {
    private var kvoStore: [NSKeyValueObservation] = []
    private let virtualKeyboardModel: VirtualKeyboardModel
    private let keyboardObserver: KeyboardObserver
    private var task: Task<Void, Never>?

    init(virtualKeyboardModel: VirtualKeyboardModel) {
        self.virtualKeyboardModel = virtualKeyboardModel
        self.keyboardObserver = .init()
        super.init()
    }

    isolated deinit {
        kvoStore.forEach { $0.invalidate() }
        kvoStore.removeAll()
        keyboardObserver.endStream()
        task?.cancel()
    }

    func observe(webView: WKWebView) {
        kvoStore.forEach { $0.invalidate() }
        kvoStore.removeAll()

        // TODO: check if need these
        // webView.scrollView.keyboardDismissMode = .none
        // webView.scrollView.contentInsetAdjustmentBehavior = .never

        let offsetObservation = webView.scrollView.observe(\.contentOffset, options: .new) { [weak self] scrollView, _ in
            Task { @MainActor [weak self] in
                guard let self, scrollView.contentOffset != .zero, self.shouldDisableScrolling() else { return }
                scrollView.setContentOffset(.zero, animated: false)
                if scrollView.isScrollEnabled {
                    scrollView.isScrollEnabled = false
                }
            }
        }
        kvoStore.append(offsetObservation)

        task?.cancel()
        keyboardObserver.endStream()
        task = Task { [weak webView, weak self, keyboardObserver] in
            for await frame in keyboardObserver.stream() {
                guard let self, let webView, !Task.isCancelled else { break }
                if frame != nil && shouldDisableScrolling() {
                    webView.scrollView.setContentOffset(.zero, animated: false)
                    webView.scrollView.isScrollEnabled = false
                }
            }
        }
    }

    private func shouldDisableScrolling() -> Bool {
        // TODO: only return true if the web page is trying to lock the viewport (will need to inject some Js)
        return virtualKeyboardModel.overlaysContent == true
    }
}
