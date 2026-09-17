import Foundation

public struct TabModel: Equatable {
    /// Position in the grid, and the runtime key for this tab's live session. Not stable
    /// across launches or deletions.
    public let index: Int
    /// Stable identity for anything persisted per tab, such as the preview thumbnail.
    public let tabID: UUID
    public let url: URL
    /// Bumped whenever a newly captured thumbnail is stored, so that a grid cell already
    /// on screen reloads the image.
    public var previewGeneration: Int

    public init(index: Int, tabID: UUID = UUID(), url: URL, previewGeneration: Int = 0) {
        self.index = index
        self.tabID = tabID
        self.url = url
        self.previewGeneration = previewGeneration
    }
}

extension TabModel: Identifiable {
    public var id: Int {
        index
    }
}
