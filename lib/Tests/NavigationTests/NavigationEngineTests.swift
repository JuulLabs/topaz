import Foundation
@testable import Navigation
import Testing
import WebKit

@MainActor
@Suite(.tags(.navigation))
struct NavigationEngineTests {

    private static var retainBucket: Set<NSObject> = []

    init() {
        _ = WKWebView()
    }

    @Test
    func decidePolicyForNavigationAction_waitsForDelegatePreparation() async {
        let delegate = MockNavigationDelegate()
        let engine = NavigationEngine(navigator: WebNavigator())
        engine.delegate = delegate
        let webView = WKWebView()
        let action = crossOriginAction(url: URL(string: "https://destination.example")!)
        let result = PolicyResultBox()

        let decision = Task { @MainActor in
            result.value = await engine.webView(webView, decidePolicyFor: action)
        }
        while !delegate.didEnterPreparation {
            await Task.yield()
        }
        #expect(result.value == nil)

        delegate.releasePreparation()
        await decision.value
        #expect(result.value == .allow)
        #expect(delegate.prepareCount == 1)
    }

    @Test
    func decidePolicyForDownload_doesNotPrepareNavigation() async {
        let delegate = MockNavigationDelegate()
        let engine = NavigationEngine(navigator: WebNavigator())
        engine.delegate = delegate
        let webView = WKWebView()
        let action = crossOriginAction(url: URL(string: "blob:https://download.example/resource")!)

        let policy = await engine.webView(webView, decidePolicyFor: action)

        #expect(policy == .download)
        #expect(delegate.prepareCount == 0)
    }

    private func crossOriginAction(url: URL) -> WKNavigationAction {
        let origin = createSecurityOrigin(protocol: "https", host: "source.example", port: 443)
        let targetFrame = MockFrameInfo(
            isMainFrame: { true },
            request: { URLRequest(url: url) },
            securityOrigin: { origin }
        ).immortalize(in: &Self.retainBucket)
        let action = MockAction(
            request: { URLRequest(url: url) },
            targetFrame: { targetFrame }
        ).immortalize(in: &Self.retainBucket)
        return action
    }
}

@MainActor
private final class MockNavigationDelegate: NavigationEngineDelegate {
    var didEnterPreparation = false
    var prepareCount = 0
    private var preparationContinuation: CheckedContinuation<Void, Never>?

    func prepareForNavigation(_ request: NavigationRequest, in webView: WKWebView) async {
        prepareCount += 1
        didEnterPreparation = true
        await withCheckedContinuation { continuation in
            preparationContinuation = continuation
        }
    }

    func releasePreparation() {
        preparationContinuation?.resume()
        preparationContinuation = nil
    }

    func didBeginLoading(_ navigation: NavigationItem, in webView: WKWebView) {}

    func didEndLoading(_ navigation: NavigationItem, in webView: WKWebView) {}

    func didTerminateWebContentProcess(in webView: WKWebView) {}

    func startedDownload(for url: URL) {}

    func completedDownload(for url: URL) {}
}

@MainActor
private final class PolicyResultBox {
    var value: WKNavigationActionPolicy?
}

private extension NSObject {
    func immortalize(in sink: inout Set<NSObject>) -> Self {
        sink.insert(self)
        return self
    }
}
