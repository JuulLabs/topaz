import Foundation
import Navigation
import Testing
import VirtualKeyboard
import WebKit
@testable import WebView

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct WebPageModelTests {

    private func makeModel(url: URL = URL(string: "https://pending-permissions.example")!) -> WebPageModel {
        WebPageModel(
            tab: 1,
            url: url,
            config: WKWebViewConfiguration(),
            navigator: WebNavigator(),
            virtualKeyboardModel: VirtualKeyboardModel()
        )
    }

    @Test
    func teardown_deniesAPendingPermissionsRequest() async throws {
        let model = makeModel()
        // Establish the page's origin so authorization gets requested rather than refused outright
        model.didBeginLoading(url: URL(string: "https://pending-permissions.example")!)
        async let pendingAuthorization = model.requestAuthorization()
        while model.presentPermissionsDialog == false {
            await Task.yield()
        }
        // Tearing down with the request still parked (e.g. the tab was evicted while
        // backgrounded, before its permissions alert could ever mount) must deny it
        // rather than leak the continuation and hang the page's promise forever
        model.teardown()
        let authorized = await pendingAuthorization
        #expect(authorized == false)
        #expect(model.presentPermissionsDialog == false)
    }

    @Test
    func teardown_withoutAPendingRequestIsHarmless() async throws {
        let model = makeModel()
        model.teardown()
        model.teardown()
        #expect(model.presentPermissionsDialog == false)
    }

    @Test
    func webView_beforeTeardownReturnsAStableInstance() async throws {
        let model = makeModel()
        let first = model.webView()
        let second = model.webView()
        #expect(first != nil)
        #expect(first === second)
    }

    @Test
    func webView_afterTeardownRefusesToResurrectTheSession() async throws {
        let model = makeModel()
        let original = model.webView()
        #expect(original != nil)
        model.teardown()
        #expect(model.isTornDown)
        // A stray view update after eviction must not conjure a replacement web view:
        // it would live outside the session cache's accounting and never be torn down
        #expect(model.webView() == nil)
    }

    @Test
    func teardown_beforeAnyWebViewExistsIsStillTerminal() async throws {
        let model = makeModel()
        model.teardown()
        #expect(model.isTornDown)
        #expect(model.webView() == nil)
    }
}
