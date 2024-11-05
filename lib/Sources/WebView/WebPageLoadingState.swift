import Foundation

public enum WebPageLoadingState {
    case initializing
    case inProgress(Float)
    case complete

    var isProgressIncomplete: Bool {
        switch self {
        case let .inProgress(progress) where progress < 1.0:
            true
        default:
            false
        }
    }

    var isProgressComplete: Bool {
        switch self {
        case let .inProgress(progress) where progress == 1.0:
            true
        default:
            false
        }
    }
}
