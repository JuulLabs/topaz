import Foundation

/// Extremely basic HTML document with a non-nesting body
public struct SimpleHtmlDocument {
    public enum Tag: String {
        case p
        case h1
    }

    private let title: String
    private var elements: [(tag: Tag, inner: String)]

    public init(title: String = "") {
        self.title = title
        self.elements = []
    }

    public mutating func addElement(_ tag: Tag, _ text: String) {
        elements.append((tag: tag, inner: text))
    }

    public func render() -> String {
        "<!doctype html>" + renderElements().joined()
    }

    private func renderElements() -> [String] {
        element(tag: "html") {
            element(tag: "head") {
                element(tag: "title") {
                    [title]
                }
            }
            +
            element(tag: "body") {
                elements.flatMap { (tag, inner) in
                    element(tag: tag.rawValue) {
                        [inner]
                    }
                }
            }
        }
    }

    private func element(tag: String, inner: () -> [String]) -> [String] {
        ["<\(tag)>"] + inner() + ["</\(tag)>"]
    }
}

extension SimpleHtmlDocument {
    public func asDataUriRequest() -> URLRequest? {
        let data = Data(render().utf8).base64EncodedString()
        return URL(string: "data:text/html;base64," + data).map { URLRequest(url: $0) }
    }
}
