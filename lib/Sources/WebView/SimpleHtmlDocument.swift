import Foundation

/// Extremely basic HTML document with a non-nesting body
struct SimpleHtmlDocument {
    enum Tag: String {
        case p
        case h1
    }

    private let title: String
    private var elements: [(tag: Tag, inner: String)]

    init(title: String = "") {
        self.title = title
        self.elements = []
    }

    mutating func addElement(_ tag: Tag, _ text: String) {
        elements.append((tag: tag, inner: text))
    }

    func render() -> String {
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
