import Foundation

extension URL {
    func isAboutBlank() -> Bool {
        absoluteString.lowercased() == "about:blank"
    }
}
