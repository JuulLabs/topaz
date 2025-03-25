import WebKit

class MockAction: MockActionWithoutSourceFrame {
    let _sourceFrame: () -> WKFrameInfo

    init(
        navigationType: WKNavigationType = .other,
        request: @escaping () -> URLRequest = { fatalError() },
        sourceFrame: @escaping () -> WKFrameInfo = { fatalError() },
        targetFrame: @escaping () -> WKFrameInfo? = { fatalError() }
    ) {
        _sourceFrame = sourceFrame
        super.init(navigationType: navigationType, request: request, targetFrame: targetFrame)
    }

    override var sourceFrame: WKFrameInfo {
        _sourceFrame()
    }
}

// sourceFrame is declared non-null but in the implementation can actually be null.
// We can force that case to be exercised by not overriding it in this sub-class.
open class MockActionWithoutSourceFrame: WKNavigationAction {
    let _navigationType: WKNavigationType
    let _request: () -> URLRequest
    let _targetFrame: () -> WKFrameInfo?

    init(
        navigationType: WKNavigationType = .other,
        request: @escaping () -> URLRequest = { fatalError() },
        targetFrame: @escaping () -> WKFrameInfo? = { fatalError() }
    ) {
        _navigationType = navigationType
        _request = request
        _targetFrame = targetFrame
    }

    override open var navigationType: WKNavigationType {
        _navigationType
    }

    override open var request: URLRequest {
        _request()
    }

    override open var targetFrame: WKFrameInfo? {
        _targetFrame()
    }
}
