import Foundation
import JsMessage

@Observable
public class WebPageModel {
    public let contextId: JsContextIdentifier
    public var url: URL

    let scriptResourceNames = ["BluetoothPolyfill"]
    let messageProcessors: [JsMessageProcessor]


    // TODO: dynamically construct this
    let customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Version/3.9.0 Topaz/3.9.0"

    public init(
        url: URL,
        messageProcessors: [JsMessageProcessor] = []
    ) {
        // TODO: additonally hash in the tab number for the case where the same URL is opened on multiple tabs
        self.contextId = url.hashValue
        self.url = url
        self.messageProcessors = messageProcessors
    }
}
