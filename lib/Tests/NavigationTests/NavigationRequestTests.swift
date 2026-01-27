import Foundation
@testable import Navigation
import Testing
import WebKit

extension Tag {
    @Tag static var navigation: Self
}

private let testUrl: URL! = URL(string: "http://test.com")

private let testRequest = URLRequest(url: testUrl)

private let nilUrlRequest: URLRequest = {
    // There is no public initializer with a nil URL so do a little dance
    var emptyRequest = URLRequest(url: testUrl)
    emptyRequest.url = nil
    return emptyRequest
}()

@MainActor
@Suite(.tags(.navigation))
struct NavigationRequestTests {

    // As of iOS 26.2 the WebKit ABI null-but-not-nullable crash is triggered on dealloc of the WK* test doubles.
    // The hacky workaround is to avoid invoking dealloc by retaining the instances in a static store.
    // Caused by https://github.com/JuulLabs/topaz/issues/180 but manifests on dealloc instead of on the getter.
    static var retainBucket: Set<NSObject> = []

    init() {
        // There is some critical init code in the framework needed for WKNavigationAction subclasses to function
        // correctly. We can force that by initializing a web view.
        _ = WKWebView()
    }

    @Test
    func initFromAction_withNilURL_isNil() {
        let action = MockAction(
            request: { nilUrlRequest }
        )
        let sut = NavigationRequest(action: action)
        #expect(sut == nil)
    }

    @Test
    func initFromAction_withValidRequest_takesUrlAndActionTypeFromAction() {
        let sourceFrame = MockFrameInfo(
            isMainFrame: { true }
        ).immortalize(in: &Self.retainBucket)
        let action = MockAction(
            navigationType: .linkActivated,
            request: { testRequest },
            sourceFrame: { sourceFrame },
            targetFrame: { nil }
        )
        let sut = NavigationRequest(action: action)
        #expect(sut?.url == testUrl)
        #expect(sut?.actionType == .linkActivated)
    }

    @Test
    func initFromAction_withNoTargetFrameAndSourceIsMainFrame_navigatesToNewWindow() {
        let sourceFrame = MockFrameInfo(
            isMainFrame: { true }
        ).immortalize(in: &Self.retainBucket)
        let action = MockAction(
            request: { testRequest },
            sourceFrame: { sourceFrame },
            targetFrame: { nil }
        )
        let sut = NavigationRequest(action: action)
        #expect(sut?.kind == .newWindow)
    }

    @Test
    func initFromAction_withNoTargetFrameAndSourceIsNotMainFrame_isNil() {
        let sourceFrame = MockFrameInfo(
            isMainFrame: { false }
        ).immortalize(in: &Self.retainBucket)
        let action = MockAction(
            request: { testRequest },
            sourceFrame: { sourceFrame },
            targetFrame: { nil }
        )
        let sut = NavigationRequest(action: action)
        #expect(sut == nil)
    }

    @Test(.disabled("https://github.com/JuulLabs/topaz/issues/180"))
    func initFromAction_withNoTargetFrameAndNoSourceFrame_isNil() {
        let action = MockActionWithoutSourceFrame(
            request: { testRequest },
            targetFrame: { nil }
        )
        let sut = NavigationRequest(action: action)
        #expect(sut == nil)
    }

    @Test
    func initFromAction_withRequestAndTargetOriginMismatch_navigatesToCrossOrigin() {
        let origin = createSecurityOrigin(protocol: "http", host: "foo.com", port: 80)
        let targetFrame = MockFrameInfo(
            isMainFrame: { true },
            request: { testRequest },
            securityOrigin: { origin }
        ).immortalize(in: &Self.retainBucket)
        let action = MockAction(
            request: { testRequest },
            targetFrame: { targetFrame }
        )
        let sut = NavigationRequest(action: action)
        #expect(sut?.kind == .crossOrigin)
    }

    @Test
    func initFromAction_withRequestAndTargetOriginMatch_navigatesToSameOrigin() throws {
        let origin = createSecurityOrigin(protocol: "http", host: "test.com", port: 80)
        let targetFrame = MockFrameInfo(
            isMainFrame: { true },
            request: { testRequest },
            securityOrigin: { origin }
        ).immortalize(in: &Self.retainBucket)
        let action = MockAction(
            request: { testRequest },
            targetFrame: { targetFrame }
        )
        let sut = NavigationRequest(action: action)
        #expect(sut?.kind == .sameOrigin)
    }
}

private extension NSObject {
    func immortalize(in sink: inout Set<NSObject>) -> Self {
        sink.insert(self)
        return self
    }
}
