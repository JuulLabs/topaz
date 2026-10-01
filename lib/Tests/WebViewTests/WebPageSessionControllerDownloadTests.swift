import Foundation
import JsMessage
import Navigation
import Testing
import VirtualKeyboard
import WebKit
@testable import WebView

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct WebPageSessionControllerDownloadTests {
    @Test
    func restoreContextAfterDownload_whenTheDownloadWasEnteredInTheSearchBar_rebindsToTheCommittedPage() async throws {
        let model = makeModel()
        guard let webView = model.webView() else {
            Issue.record("Expected model to create a web view")
            return
        }
        let committedURL = URL(string: "https://original.example/page")!
        let downloadURL = URL(string: "https://download.example/archive.zip")!
        model.sessionController.handleCommittedLoad(url: committedURL, in: webView)
        await model.sessionController.awaitPendingContextSwap()

        model.loadNewPage(url: downloadURL)
        model.sessionController.update(webView: webView, model: model)
        await model.sessionController.prepareForNavigation(navigationRequest(url: downloadURL), in: webView)
        let downloadHandler = try #require(model.sessionController.scriptHandler)

        await model.sessionController.restoreContextAfterDownload(in: webView)

        #expect(model.sessionController.contextId.url == committedURL)
        #expect(model.sessionController.scriptHandler !== downloadHandler)
        model.teardown()
    }

    @Test
    func restoreContextAfterDownload_whenTheDownloadStartsBeforeTheCommittedPageFinishes_rebindsToTheCommittedPage() async throws {
        let model = makeModel()
        guard let webView = model.webView() else {
            Issue.record("Expected model to create a web view")
            return
        }
        let lastLoadedURL = URL(string: "https://previous.example/page")!
        let committedURL = URL(string: "https://committed.example/page")!
        let downloadURL = URL(string: "https://download.example/archive.zip")!
        model.loadNewPage(url: lastLoadedURL)
        model.sessionController.update(webView: webView, model: model)
        model.sessionController.handleCommittedLoad(url: committedURL, in: webView)
        await model.sessionController.awaitPendingContextSwap()
        await model.sessionController.prepareForNavigation(
            navigationRequest(url: downloadURL, isDownload: true),
            in: webView
        )

        await model.sessionController.restoreContextAfterDownload(in: webView)

        #expect(model.sessionController.contextId.url == committedURL)
        model.teardown()
    }

    @Test
    func restoreContextAfterDownload_withASameHostDownloadBeforeTheCommittedPageFinishes_keepsTheCurrentContext() async throws {
        let model = makeModel()
        guard let webView = model.webView() else {
            Issue.record("Expected model to create a web view")
            return
        }
        let lastLoadedURL = URL(string: "https://previous.example/page")!
        let committedURL = URL(string: "https://committed.example/page")!
        let downloadURL = URL(string: "https://committed.example/archive.zip")!
        model.loadNewPage(url: lastLoadedURL)
        model.sessionController.update(webView: webView, model: model)
        model.sessionController.handleCommittedLoad(url: committedURL, in: webView)
        await model.sessionController.awaitPendingContextSwap()
        let committedHandler = try #require(model.sessionController.scriptHandler)
        await model.sessionController.prepareForNavigation(
            navigationRequest(url: downloadURL, isDownload: true),
            in: webView
        )

        await model.sessionController.restoreContextAfterDownload(in: webView)

        #expect(model.sessionController.scriptHandler === committedHandler)
        #expect(model.sessionController.contextId.url == committedURL)
        model.teardown()
    }

    private func makeModel() -> WebPageModel {
        WebPageModel(
            tab: 1,
            url: URL(string: "https://initial.example")!,
            config: WKWebViewConfiguration(),
            messageProcessorFactory: JsMessageProcessorFactory(),
            navigator: WebNavigator(),
            virtualKeyboardModel: VirtualKeyboardModel()
        )
    }

    private func navigationRequest(url: URL, isDownload: Bool = false) -> NavigationRequest {
        NavigationRequest(
            url: url,
            kind: .crossOrigin,
            actionType: .other,
            isDownload: isDownload,
            httpMethod: nil,
            isMainFrame: true
        )
    }
}
