import Foundation
@testable import Navigation
import Testing
import WebKit

@MainActor
@Suite(.tags(.navigation))
/// Exercises `NavigationEngine`'s `WKNavigationDelegate` policy decisions for navigation
/// actions and responses, verifying that WebKit waits for the delegate's context work.
struct NavigationEngineTests {

    // As of iOS 26.2 the WebKit ABI null-but-not-nullable crash is triggered on dealloc of the WK* test doubles.
    // The hacky workaround is to avoid invoking dealloc by retaining the instances in a static store.
    // Caused by https://github.com/JuulLabs/topaz/issues/180 but manifests on dealloc instead of on the getter.
    private static var retainBucket: Set<NSObject> = []

    init() {
        // There is some critical init code in the framework needed for WKNavigationAction subclasses to function
        // correctly. We can force that by initializing a web view.
        _ = WKWebView()
    }

    @Test
    func decidePolicyForAction_whileTheDelegateIsPreparingTheContext_withholdsTheDecision() async {
        let delegate = MockNavigationDelegate()
        let sut = makeSut(delegate: delegate)
        let webView = WKWebView()
        let action = crossOriginAction(url: URL(string: "https://destination.example")!)
        let result = PolicyResultBox()

        let decision = Task { @MainActor in
            result.value = await sut.webView(webView, decidePolicyFor: action)
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
    func decidePolicyForAction_withADownloadAction_returnsDownloadWithoutPreparingAContext() async {
        let delegate = MockNavigationDelegate()
        let sut = makeSut(delegate: delegate)
        let webView = WKWebView()
        let action = crossOriginAction(url: URL(string: "blob:https://download.example/resource")!)

        let policy = await sut.webView(webView, decidePolicyFor: action)

        #expect(policy == .download)
        #expect(delegate.prepareCount == 0)
    }

    @Test
    func decidePolicyForResponse_whenTheResponseConvertsToADownload_restoresTheContextBeforeDownloading() async {
        let delegate = MockNavigationDelegate()
        delegate.gatePreparation = false
        let sut = makeSut(delegate: delegate)
        let webView = WKWebView()
        let url = URL(string: "https://download.example/archive.zip")!
        let action = crossOriginAction(url: url)
        _ = await sut.webView(webView, decidePolicyFor: action)
        let response = navigationResponse(
            url: url,
            isForMainFrame: true,
            canShowMIMEType: false
        )

        let decision = Task { @MainActor in
            await sut.webView(webView, decidePolicyFor: response)
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
    func decidePolicyForResponse_withAnOrdinaryPageResponse_leavesTheContextAttached() async {
        let delegate = MockNavigationDelegate()
        delegate.gatePreparation = false
        let sut = makeSut(delegate: delegate)
        let webView = WKWebView()
        let url = URL(string: "https://allowed.example/page")!
        let action = crossOriginAction(url: url)
        _ = await sut.webView(webView, decidePolicyFor: action)
        let response = navigationResponse(
            url: url,
            isForMainFrame: true,
            canShowMIMEType: true
        )

        let policy = await sut.webView(webView, decidePolicyFor: response)

        #expect(policy == .allow)
        #expect(delegate.restoreCount == 0)
    }

    private func makeSut(delegate: MockNavigationDelegate) -> NavigationEngine {
        let sut = NavigationEngine(navigator: WebNavigator())
        sut.delegate = delegate
        return sut
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
            sourceFrame: { targetFrame },
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
