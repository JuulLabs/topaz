import Foundation

// For when we need to indicate the download is complete but the ProgressReporter does not tell us so
class ArtificialFinishedProgress: Progress, @unchecked Sendable {
    init(finalCount: Int64) {
        super.init(parent: nil, userInfo: nil)
        totalUnitCount = finalCount
        completedUnitCount = finalCount
    }

    override var isFinished: Bool { true }
    override var isCancelled: Bool { false }
    override var fractionCompleted: Double { 1 }
    override var isIndeterminate: Bool { false }
}
