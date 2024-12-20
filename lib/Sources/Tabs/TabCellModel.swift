import Foundation

struct Tab: Equatable {
    let index: Int
    let url: URL
}

enum TabCell: Equatable {
    case tab(Tab)
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
