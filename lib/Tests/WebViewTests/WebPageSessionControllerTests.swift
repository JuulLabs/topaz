import Foundation
import JsMessage
import Navigation
import Testing
import VirtualKeyboard
import WebKit
@testable import WebView

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct WebPageSessionControllerTests {

    @Test
    func firstCrossOriginMainFrameRequest_attachesNewContextBeforeReturning() async throws {
        let recorder = EventRecorder()
        let model = makeModel(recorder: recorder)
        guard let webView = model.webView() else {
            Issue.record("Expected model to create a web view")
            return
        }
        let request = navigationRequest(url: URL(string: "https://first.example")!)

        await model.sessionController.prepareForNavigation(request, in: webView)

        #expect(model.sessionController.scriptHandler != nil)
        #expect(model.sessionController.contextId.url == request.url)
        model.teardown()
    }

    @Test
    func crossOriginSubframeRequest_keepsCurrentContext() async throws {
        let recorder = EventRecorder()
        let model = makeModel(recorder: recorder)
        guard let webView = model.webView() else {
            Issue.record("Expected model to create a web view")
            return
        }
        let firstRequest = navigationRequest(url: URL(string: "https://first.example")!)
        await model.sessionController.prepareForNavigation(firstRequest, in: webView)
        let handler = model.sessionController.scriptHandler
        let context = model.sessionController.contextId
        let subframeRequest = navigationRequest(url: URL(string: "https://frame.example")!, isMainFrame: false)

        await model.sessionController.prepareForNavigation(subframeRequest, in: webView)

        #expect(model.sessionController.scriptHandler === handler)
        #expect(model.sessionController.contextId == context)
        model.teardown()
    }

    @Test
    func crossOriginDownload_keepsCurrentContext() async throws {
        let recorder = EventRecorder()
        let model = makeModel(recorder: recorder)
        guard let webView = model.webView() else {
            Issue.record("Expected model to create a web view")
            return
        }
        let firstRequest = navigationRequest(url: URL(string: "https://first.example")!)
        await model.sessionController.prepareForNavigation(firstRequest, in: webView)
        let handler = model.sessionController.scriptHandler
        let context = model.sessionController.contextId
        let downloadRequest = navigationRequest(url: URL(string: "https://download.example/file")!, isDownload: true)

        await model.sessionController.prepareForNavigation(downloadRequest, in: webView)

        #expect(model.sessionController.scriptHandler === handler)
        #expect(model.sessionController.contextId == context)
        model.teardown()
    }

    @Test
    func sameHostRedirect_keepsTheAttachedScriptHandler() async throws {
        let recorder = EventRecorder()
        let model = makeModel(recorder: recorder)
        guard let webView = model.webView() else {
            Issue.record("Expected model to create a web view")
            return
        }
        let firstRequest = navigationRequest(url: URL(string: "https://first.example/one")!)
        await model.sessionController.prepareForNavigation(firstRequest, in: webView)
        let handler = model.sessionController.scriptHandler
        let redirectRequest = navigationRequest(url: URL(string: "https://first.example/two")!)

        await model.sessionController.prepareForNavigation(redirectRequest, in: webView)

        #expect(model.sessionController.scriptHandler === handler)
        #expect(await recorder.events() == [])
        model.teardown()
    }

    @Test
    func sameOriginRequestWithDifferentHost_swapsContext() async throws {
        let recorder = EventRecorder()
        let model = makeModel(recorder: recorder)
        guard let webView = model.webView() else {
            Issue.record("Expected model to create a web view")
            return
        }
        let firstURL = URL(string: "https://first.example")!
        let secondURL = URL(string: "https://second.example")!
        await model.sessionController.prepareForNavigation(navigationRequest(url: firstURL), in: webView)
        let firstHandler = try #require(model.sessionController.scriptHandler)

        await model.sessionController.prepareForNavigation(
            navigationRequest(url: secondURL, kind: .sameOrigin),
            in: webView
        )

        #expect(model.sessionController.scriptHandler !== firstHandler)
        #expect(model.sessionController.contextId.url == secondURL)
        model.teardown()
    }

    @Test
    func sameOriginRequestWithSameHost_keepsCurrentContext() async throws {
        let recorder = EventRecorder()
        let model = makeModel(recorder: recorder)
        guard let webView = model.webView() else {
            Issue.record("Expected model to create a web view")
            return
        }
        let firstURL = URL(string: "https://first.example/one")!
        let secondURL = URL(string: "https://first.example/two")!
        await model.sessionController.prepareForNavigation(navigationRequest(url: firstURL), in: webView)
        let firstHandler = try #require(model.sessionController.scriptHandler)

        await model.sessionController.prepareForNavigation(
            navigationRequest(url: secondURL, kind: .sameOrigin),
            in: webView
        )

        #expect(model.sessionController.scriptHandler === firstHandler)
        #expect(model.sessionController.contextId.url == firstURL)
        model.teardown()
    }

    @Test
    func newWindowRequest_keepsCurrentContext() async throws {
        let recorder = EventRecorder()
        let model = makeModel(recorder: recorder)
        guard let webView = model.webView() else {
            Issue.record("Expected model to create a web view")
            return
        }
        let firstURL = URL(string: "https://first.example")!
        let newWindowURL = URL(string: "https://second.example")!
        await model.sessionController.prepareForNavigation(navigationRequest(url: firstURL), in: webView)
        let firstHandler = try #require(model.sessionController.scriptHandler)

        await model.sessionController.prepareForNavigation(
            navigationRequest(url: newWindowURL, kind: .newWindow),
            in: webView
        )

        #expect(model.sessionController.scriptHandler === firstHandler)
        #expect(model.sessionController.contextId.url == firstURL)
        model.teardown()
    }

    @Test
    func restoreContextAfterDownload_rebindsToVisiblePageURL() async throws {
        let recorder = EventRecorder()
        let model = makeModel(recorder: recorder)
        guard let webView = model.webView() else {
            Issue.record("Expected model to create a web view")
            return
        }
        let originalURL = URL(string: "https://original.example/page")!
        let downloadURL = URL(string: "https://download.example/archive.zip")!
        await model.sessionController.prepareForNavigation(navigationRequest(url: originalURL), in: webView)
        await model.sessionController.prepareForNavigation(navigationRequest(url: downloadURL), in: webView)
        let downloadHandler = try #require(model.sessionController.scriptHandler)

        await model.sessionController.restoreContextAfterDownload(pageURL: originalURL, in: webView)

        #expect(model.sessionController.scriptHandler !== downloadHandler)
        #expect(model.sessionController.contextId.url == originalURL)
        model.teardown()
    }

    @Test
    func restoreContextAfterDownload_withMatchingHostOrNoHandler_isNoOp() async throws {
        let recorder = EventRecorder()
        let model = makeModel(recorder: recorder)
        guard let webView = model.webView() else {
            Issue.record("Expected model to create a web view")
            return
        }
        let originalURL = URL(string: "https://original.example/page")!
        await model.sessionController.prepareForNavigation(navigationRequest(url: originalURL), in: webView)
        let handler = try #require(model.sessionController.scriptHandler)

        await model.sessionController.restoreContextAfterDownload(
            pageURL: URL(string: "https://original.example/other")!,
            in: webView
        )

        #expect(model.sessionController.scriptHandler === handler)
        #expect(model.sessionController.contextId.url == originalURL)
        model.teardown()

        let unattachedModel = makeModel(recorder: recorder)
        guard let unattachedWebView = unattachedModel.webView() else {
            Issue.record("Expected model to create a web view")
            return
        }
        await unattachedModel.sessionController.restoreContextAfterDownload(
            pageURL: originalURL,
            in: unattachedWebView
        )
        #expect(unattachedModel.sessionController.scriptHandler == nil)
        unattachedModel.teardown()
    }

    @Test
    func crossOriginSwap_waitsForProcessorDetachBeforeAttachingReplacement() async throws {
        let recorder = EventRecorder()
        let model = makeModel(recorder: recorder)
        guard let webView = model.webView() else {
            Issue.record("Expected model to create a web view")
            return
        }
        let firstURL = URL(string: "https://first.example")!
        let secondURL = URL(string: "https://second.example")!
        await model.sessionController.prepareForNavigation(navigationRequest(url: firstURL), in: webView)
        let firstHandler = try #require(model.sessionController.scriptHandler)
        #expect(await firstHandler.getProcessor(named: SpyProcessor.handlerName) != nil)
        #expect(await recorder.events() == ["attach(first.example)"])

        await model.sessionController.prepareForNavigation(navigationRequest(url: secondURL), in: webView)

        #expect(await recorder.events() == ["attach(first.example)", "detach(first.example)"])
        #expect(model.sessionController.scriptHandler !== firstHandler)
        #expect(model.sessionController.contextId.url == secondURL)
        model.teardown()
    }

    @Test
    func consecutiveCrossOriginSwaps_leaveOnlyTheLastContextAttached() async throws {
        let recorder = EventRecorder()
        let model = makeModel(recorder: recorder)
        guard let webView = model.webView() else {
            Issue.record("Expected model to create a web view")
            return
        }
        let firstURL = URL(string: "https://first.example")!
        let secondURL = URL(string: "https://second.example")!
        let thirdURL = URL(string: "https://third.example")!

        await model.sessionController.prepareForNavigation(navigationRequest(url: firstURL), in: webView)
        let firstHandler = try #require(model.sessionController.scriptHandler)
        await model.sessionController.prepareForNavigation(navigationRequest(url: secondURL), in: webView)
        let secondHandler = try #require(model.sessionController.scriptHandler)
        await model.sessionController.prepareForNavigation(navigationRequest(url: thirdURL), in: webView)
        let thirdHandler = try #require(model.sessionController.scriptHandler)

        #expect(firstHandler !== secondHandler)
        #expect(secondHandler !== thirdHandler)
        #expect(model.sessionController.scriptHandler === thirdHandler)
        #expect(model.sessionController.contextId.url == thirdURL)
        model.teardown()
    }

    private func makeModel(recorder: EventRecorder) -> WebPageModel {
        let factory = JsMessageProcessorFactory(builders: [
            SpyProcessor.handlerName: { @MainActor context in
                SpyProcessor(host: context.id.url.host(percentEncoded: false) ?? "unknown", recorder: recorder)
            },
        ])
        return WebPageModel(
            tab: 1,
            url: URL(string: "https://initial.example")!,
            config: WKWebViewConfiguration(),
            messageProcessorFactory: factory,
            navigator: WebNavigator(),
            virtualKeyboardModel: VirtualKeyboardModel()
        )
    }

    private func navigationRequest(
        url: URL,
        kind: NavigationKind = .crossOrigin,
        isMainFrame: Bool = true,
        isDownload: Bool = false
    ) -> NavigationRequest {
        NavigationRequest(
            url: url,
            kind: kind,
            actionType: .other,
            isDownload: isDownload,
            httpMethod: nil,
            isMainFrame: isMainFrame
        )
    }
}

private actor EventRecorder {
    private var recordedEvents: [String] = []

    func record(_ event: String) {
        recordedEvents.append(event)
    }

    func events() -> [String] {
        recordedEvents
    }
}

private actor SpyProcessor: JsMessageProcessor {
    static let handlerName = "spy"
    let host: String
    let recorder: EventRecorder
    let enableDebugLogging = false

    init(host: String, recorder: EventRecorder) {
        self.host = host
        self.recorder = recorder
    }

    func didAttach(to context: JsContext) async {
        await recorder.record("attach(\(host))")
    }

    func didDetach(from context: JsContext) async {
        await Task.yield()
        await recorder.record("detach(\(host))")
    }

    func process(request: JsMessageRequest, in context: JsContext) async -> JsMessageResponse {
        .error(DomError(name: .notSupported, message: "Not implemented"))
    }
}
