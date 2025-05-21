import Foundation

public struct TabModel: Equatable {
    public let index: Int
    public let url: URL
}

extension TabModel: Identifiable {
    public var id: Int {
        index
    }
}
