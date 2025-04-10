import Helpers
import Observation
import SwiftUI

@MainActor
@Observable
public final class PermissionsModel {
    private var storage: CodableStorage?
    private(set) var models: [WebOriginViewModel]

    public init(origins: [WebOrigin] = []) {
        self.models = Self.originsToViewModels(origins)
    }

    public func isAuthorized(origin: WebOrigin) -> Bool {
        return models.contains { $0.origin == origin }
    }

    func removeRows(atOffsets offsets: IndexSet) {
        models.remove(atOffsets: offsets)
        saveAll()
    }

    public func attachToStorage(_ storage: CodableStorage) async {
        self.storage = storage
        if let origins: [WebOrigin] = try? await storage.load(for: .allowedOriginsKey) {
            self.models = Self.originsToViewModels(origins)
        }
    }

    private func saveAll() {
        guard let storage else { return }
        let origins = models.map { $0.origin }
        Task {
            try await storage.save(origins, for: .allowedOriginsKey)
        }
    }

    static func originsToViewModels(_ origins: [WebOrigin]) -> [WebOriginViewModel] {
        return origins.map { origin in
            WebOriginViewModel(origin: origin, displayString: displayString(for: origin, in: origins))
        }
    }
}

fileprivate extension String {
    static let allowedOriginsKey = "allowedOrigins"
}

func displayString(for origin: WebOrigin, in origins: [WebOrigin]) -> String {
    let matches = origins.filter { other in
        other.domain == origin.domain
    }
    guard matches.count > 1 else {
        // Domain is unique so show only domain
        return origin.domain
    }
    let schemeCount = Set(matches.map({$0.scheme})).count
    let portCount = Set(matches.map({$0.port})).count
    var displayString = ""
    if schemeCount > 1 {
        // Show the scheme to differentiate
        displayString += "\(origin.scheme)://"
    }
    displayString += origin.domain
    if portCount > 1 {
        // Show the port to differentiate
        displayString += ":\(origin.port)"
    }
    return displayString
}
