import Foundation

public enum WebPageLoadingState: Sendable {
    case initializing
    case inProgress(Float)
    case complete(URL)

    public var isProgressIncomplete: Bool {
        switch self {
        case let .inProgress(progress) where progress < 1.0:
            true
        default:
            false
        }
    }

    public var isProgressComplete: Bool {
        switch self {
        case let .inProgress(progress) where progress == 1.0:
            true
        default:
            false
        }
    }
}
