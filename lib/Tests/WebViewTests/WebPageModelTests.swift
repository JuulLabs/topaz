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
    func teardown_withAPermissionsRequestStillPending_deniesIt() async throws {
        let model = makeModel()
        // Establish the page origin so authorization is requested rather than refused outright
        model.didBeginLoading(url: URL(string: "https://pending-permissions.example")!)
        async let pendingAuthorization = model.requestAuthorization()
        while model.presentPermissionsDialog == false {
            await Task.yield()
        }
        // Otherwise the continuation leaks and hangs the page promise forever. The tab may
        // have been evicted while backgrounded, before its permissions alert could mount.
        model.teardown()
        let authorized = await pendingAuthorization
        #expect(authorized == false)
        #expect(model.presentPermissionsDialog == false)
    }

    @Test
    func teardown_withoutAPendingRequest_isHarmlessWhenRepeated() async throws {
        let model = makeModel()
        model.teardown()
        model.teardown()
        #expect(model.presentPermissionsDialog == false)
    }

    @Test
    func webView_whenCalledRepeatedlyBeforeTeardown_returnsTheSameInstance() async throws {
        let model = makeModel()
        let first = model.webView()
        let second = model.webView()
        #expect(first != nil)
        #expect(first === second)
    }

    @Test
    func webView_afterTeardown_refusesToResurrectTheSession() async throws {
        let model = makeModel()
        let original = model.webView()
        #expect(original != nil)
        model.teardown()
        #expect(model.isTornDown)
        // A stray view update after eviction must not conjure a replacement web view
        #expect(model.webView() == nil)
    }

    @Test
    func teardown_beforeAnyWebViewExists_isStillTerminal() async throws {
        let model = makeModel()
        model.teardown()
        #expect(model.isTornDown)
        #expect(model.webView() == nil)
    }
}
