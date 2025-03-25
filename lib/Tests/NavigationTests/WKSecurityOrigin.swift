import WebKit

/**
 WKSecurityOrigin initializer is marked as `NS_UNAVAILABLE`.
 The use case is simple enough that we can treat the class like a hard-protocol overlay and sub in an imposter.
 */
func createSecurityOrigin(
    `protocol`: String,
    host: String,
    port: Int
) -> WKSecurityOrigin {
    @objc class FakeSecurityOrigin: NSObject {
        @objc let `protocol`: String
        @objc let host: String
        @objc let port: Int

        init(`protocol`: String, host: String, port: Int) {
            self.protocol = `protocol`
            self.host = host
            self.port = port
        }
    }
    let imposter = FakeSecurityOrigin(protocol: `protocol`, host: host, port: port)
    return unsafeBitCast(imposter, to: WKSecurityOrigin.self)
}
