import WebKit

class MockFrameInfo: WKFrameInfo {
    let _isMainFrame: () -> Bool
    let _request: () -> URLRequest
    let _securityOrigin: () -> WKSecurityOrigin

    init(
        isMainFrame: @escaping () -> Bool = { fatalError() },
        request: @escaping () -> URLRequest = { fatalError() },
        securityOrigin: @escaping () -> WKSecurityOrigin = { fatalError() }
    ) {
        _isMainFrame = isMainFrame
        _request = request
        _securityOrigin = securityOrigin
    }

    override var isMainFrame: Bool {
        _isMainFrame()
    }

    override open var request: URLRequest {
        _request()
    }

    override var securityOrigin: WKSecurityOrigin {
        _securityOrigin()
    }
}
