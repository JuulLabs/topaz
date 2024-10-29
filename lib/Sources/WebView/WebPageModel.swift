import Foundation
import JsMessage
import Observation

@MainActor
@Observable
public class WebPageModel {
    public let contextId: JsContextIdentifier
    public let tab: Int
    public private(set) var url: URL

    let scriptResourceNames = ["BluetoothPolyfill"]
    let messageProcessors: [JsMessageProcessor]

    // TODO: dynamically construct this
    let customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Version/3.9.0 Topaz/3.9.0"

    public var hostname: String {
        url.host(percentEncoded: false) ?? "unknown"
    }

    public init(
        tab: Int,
        url: URL,
        messageProcessors: [JsMessageProcessor] = []
    ) {
        self.contextId = JsContextIdentifier(tab: tab, url: url)
        self.tab = tab
        self.url = url
        self.messageProcessors = messageProcessors
    }

    public func loadNewPage(url: URL) {
        self.url = url
    }
}
