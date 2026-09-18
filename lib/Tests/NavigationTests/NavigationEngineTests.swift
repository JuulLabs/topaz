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

    @Test
    func decidePolicyForResponseDownload_waitsForRestoreAndReturnsDownload() async {
        let delegate = MockNavigationDelegate()
        delegate.gatePreparation = false
        let engine = NavigationEngine(navigator: WebNavigator())
        engine.delegate = delegate
        let webView = WKWebView()
        let url = URL(string: "https://download.example/archive.zip")!
        let action = crossOriginAction(url: url)
        _ = await engine.webView(webView, decidePolicyFor: action)
        let response = navigationResponse(
            url: url,
            isForMainFrame: true,
            canShowMIMEType: false
        )

        let decision = Task { @MainActor in
            await engine.webView(webView, decidePolicyFor: response)
        }
        while !delegate.didEnterRestore {
            await Task.yield()
        }
        #expect(delegate.restoreResult == nil)

        delegate.releaseRestore()
        #expect(await decision.value == .download)
        #expect(delegate.restoreCount == 1)
    }

    @Test
    func decidePolicyForAllowedResponse_doesNotRestoreContext() async {
        let delegate = MockNavigationDelegate()
        delegate.gatePreparation = false
        let engine = NavigationEngine(navigator: WebNavigator())
        engine.delegate = delegate
        let webView = WKWebView()
        let url = URL(string: "https://allowed.example/page")!
        let action = crossOriginAction(url: url)
        _ = await engine.webView(webView, decidePolicyFor: action)
        let response = navigationResponse(
            url: url,
            isForMainFrame: true,
            canShowMIMEType: true
        )

        let policy = await engine.webView(webView, decidePolicyFor: response)

        #expect(policy == .allow)
        #expect(delegate.restoreCount == 0)
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

    private func navigationResponse(
        url: URL,
        isForMainFrame: Bool,
        canShowMIMEType: Bool
    ) -> WKNavigationResponse {
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        let imposter = MockNavigationResponse(
            response: response,
            isForMainFrame: isForMainFrame,
            canShowMIMEType: canShowMIMEType
        ).immortalize(in: &Self.retainBucket)
        return unsafeBitCast(imposter, to: WKNavigationResponse.self)
    }
}

@MainActor
private final class MockNavigationDelegate: NavigationEngineDelegate {
    var didEnterPreparation = false
    var prepareCount = 0
    var gatePreparation = true
    var didEnterRestore = false
    var restoreCount = 0
    var restoreResult: WKNavigationResponsePolicy?
    private var preparationContinuation: CheckedContinuation<Void, Never>?
    private var restoreContinuation: CheckedContinuation<Void, Never>?

    func prepareForNavigation(_ request: NavigationRequest, in webView: WKWebView) async {
        prepareCount += 1
        didEnterPreparation = true
        guard gatePreparation else { return }
        await withCheckedContinuation { continuation in
            preparationContinuation = continuation
        }
    }

    func releasePreparation() {
        preparationContinuation?.resume()
        preparationContinuation = nil
    }

    func restoreContextAfterDownload(in webView: WKWebView) async {
        restoreCount += 1
        didEnterRestore = true
        await withCheckedContinuation { continuation in
            restoreContinuation = continuation
        }
    }

    func releaseRestore() {
        restoreContinuation?.resume()
        restoreContinuation = nil
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

private final class MockNavigationResponse: NSObject {
    @objc let response: URLResponse
    @objc let isForMainFrame: Bool
    @objc let canShowMIMEType: Bool

    init(response: URLResponse, isForMainFrame: Bool, canShowMIMEType: Bool) {
        self.response = response
        self.isForMainFrame = isForMainFrame
        self.canShowMIMEType = canShowMIMEType
    }
}
