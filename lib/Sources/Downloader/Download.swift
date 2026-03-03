import Foundation
import Observation
import OSLog
import SwiftUI

@MainActor
@Observable
public final class Download: Identifiable {
    public enum State { case downloading, finished, failed }

    public let id: Int
    public let destinationURL: URL

    private(set) var state: State
    private(set) var percentageProgress: Double?
    private(set) var bytesProgress: Int64?
    private(set) var errorDescription: String?
    private(set) var progressObserver: ProgressObserver?

    var isPresentingShareSheet = false

    let creationDate: Date = .init()

    public init(
        id: Int,
        destinationURL: URL,
        state: State = .downloading,
        percentageProgress: Double? = nil,
        bytesProgress: Int64? = nil,
        errorDescription: String? = nil
    ) {
        self.id = id
        self.destinationURL = destinationURL
        self.state = state
        self.percentageProgress = percentageProgress
        self.bytesProgress = bytesProgress
        self.errorDescription = errorDescription
    }

    var titleText: String {
        destinationURL.lastPathComponent
    }

    var subtitleText: String {
        switch state {
        case .downloading: percentProgressText ?? bytesProgressText ?? "Downloading..."
        case .finished: bytesProgressText.map { "Downloaded \($0)" } ?? "Downloaded"
        case .failed: errorDescription ?? "Download failed"
        }
    }

    var progressToShow: Double? {
        state == .downloading ? percentageProgress : nil
    }

    private var percentProgressText: String? {
        percentageProgress.map { "\(($0 * 100).formatted(.number.precision(.fractionLength(0))))%" }
    }

    private var bytesProgressText: String? {
        bytesProgress.map { "\($0.formatted(.number.grouping(.automatic))) bytes" }
    }

    func cancelButtonTapped() {
        progressObserver?.cancel()
        errorDescription = "Cancelled"
    }

    func exportButtonTapped() {
        isPresentingShareSheet = true
    }

    func setFailed(_ error: Error) {
        state = .failed
        errorDescription = error.localizedDescription
        progressObserver?.cancel()
    }

    func trackUpdates(using progressReporting: ProgressReporting) async {
        let observer = ProgressObserver(progressReporting: progressReporting)
        progressObserver = observer
        for await progress in observer.progressStream {
            update(with: progress)
        }
        progressObserver = nil
        if state == .downloading {
            // Probably cancelled and not notified
            state = .failed
        }
    }

    private func update(with progress: Progress) {
        percentageProgress = progress.fractionCompleted > 0 ? progress.fractionCompleted : nil
        bytesProgress = progress.completedUnitCount > 0 ? progress.completedUnitCount : nil
        guard state == .downloading else { return }
        if progress.isFinished {
            state = .finished
        } else if progress.isCancelled {
            state = .failed
        }
    }
}
