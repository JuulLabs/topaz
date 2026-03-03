import Foundation
import Observation

class ProgressObserver {
    private var cancelAction: (() -> Void)?
    private var observations: [NSKeyValueObservation]

    let progressStream: AsyncStream<Progress>
    private let continuation: AsyncStream<Progress>.Continuation

    init(progressReporting: ProgressReporting) {
        let progress = progressReporting.progress
        cancelAction = { progress.cancel() }
        let (stream, continuation) = AsyncStream<Progress>.makeStream()
        progressStream = stream
        self.continuation = continuation

        let emitAndMaybeFinish = { @Sendable (progress: Progress, _: Any) in
            continuation.yield(progress)
            if progress.isFinished || progress.isCancelled {
                continuation.yield(progress)
                continuation.finish()
            } else if progress.totalUnitCount > 0 && progress.completedUnitCount >= progress.totalUnitCount {
                continuation.yield(ArtificialFinishedProgress(finalCount: progress.completedUnitCount))
                continuation.finish()
            } else {
                continuation.yield(progress)
            }
        }

        continuation.yield(progress)
        observations = [
            progress.observe(\.fractionCompleted, changeHandler: emitAndMaybeFinish),
            progress.observe(\.completedUnitCount, changeHandler: emitAndMaybeFinish),
            progress.observe(\.totalUnitCount, changeHandler: emitAndMaybeFinish),
            progress.observe(\.isCancelled, changeHandler: emitAndMaybeFinish),
        ]
    }

    deinit {
        cleanup(invokeCancelAction: false)
    }

    func cancel() {
        cleanup(invokeCancelAction: true)
    }

    func finish(finalProgress: Progress) {
        if !finalProgress.isFinished && !finalProgress.isCancelled {
            continuation.yield(ArtificialFinishedProgress(finalCount: finalProgress.completedUnitCount))
        } else {
            continuation.yield(finalProgress)
        }
        cleanup(invokeCancelAction: false)
    }

    private func cleanup(invokeCancelAction: Bool) {
        if invokeCancelAction {
            cancelAction?()
        }
        cancelAction = nil
        observations.forEach { $0.invalidate() }
        observations.removeAll()
        continuation.finish()
    }
}
