import Foundation

struct WebOriginViewModel: Equatable, Identifiable {
    let origin: WebOrigin
    let displayString: String

    var id: String {
        origin.urlStringRepresentation
    }

    init(origin: WebOrigin, displayString: String) {
        self.origin = origin
        self.displayString = displayString
    }
}
