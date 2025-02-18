import Foundation

public struct TabModel: Equatable {
    public let index: Int
    public let url: URL?
}

enum TabCell: Equatable {
    case tab(TabModel)
    case new
}

extension TabCell: Identifiable {
    var id: Int {
        switch self {
        case let .tab(tab):
            return tab.index
        case .new:
            return 0
        }
    }
}
