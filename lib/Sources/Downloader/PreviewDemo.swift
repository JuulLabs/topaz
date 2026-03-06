#if targetEnvironment(simulator)
import SwiftUI

#Preview("Download List") {
    let model = Downloads()
    NavigationStack {
        DownloadListView(model: model)
            .task {
                struct FakeNetworkError: Error, LocalizedError {
                    var errorDescription: String? { "Network error" }
                }
                let archiveReporter = FakeProgressReporter(count: 1000)
                let imageReporter = FakeProgressReporter()
                let report1Reporter = FakeProgressReporter()
                model.beginDownload(url: URL(fileURLWithPath: "/tmp/Archive.zip"), for: archiveReporter)
                model.beginDownload(url: URL(fileURLWithPath: "/tmp/Image.png"), for: imageReporter)
                model.beginDownload(url: URL(fileURLWithPath: "/tmp/Report1.pdf"), for: report1Reporter)
                try? await Task.sleep(nanoseconds: NSEC_PER_SEC * 2)
                let report2Reporter = FakeProgressReporter(injectedProgress: IndeterminateProgress())
                model.beginDownload(url: URL(fileURLWithPath: "/tmp/Report2.pdf"), for: report2Reporter)
                try? await Task.sleep(nanoseconds: NSEC_PER_SEC)
                model.cancelDownload(for: imageReporter, with: FakeNetworkError())
                try? await Task.sleep(nanoseconds: NSEC_PER_SEC * 3)
                model.finishDownload(for: report2Reporter)
            }
    }
    .forceLoadFontsInPreview()
}

#Preview("No Downloads") {
    NavigationStack { DownloadListView(model: Downloads()) }
}

private class FakeProgressReporter: NSObject, ProgressReporting {
    let progress: Progress

    init(count: Int64 = 0, injectedProgress: Progress? = nil) {
        progress = injectedProgress ?? Progress(totalUnitCount: 1000)
        super.init()
        progress.completedUnitCount = count
        Task { [progress] in
            if progress.isIndeterminate {
                while !progress.isCancelled {
                    progress.completedUnitCount += 1
                    try? await Task.sleep(nanoseconds: 20_000)
                }
            } else {
                while progress.completedUnitCount < progress.totalUnitCount && !progress.isCancelled {
                    progress.completedUnitCount += 1
                    try? await Task.sleep(nanoseconds: NSEC_PER_SEC / 200)
                }
            }
        }
    }
}

private class IndeterminateProgress: Progress, @unchecked Sendable {
    init() {
        super.init(parent: nil, userInfo: nil)
        totalUnitCount = 0
        completedUnitCount = 0
    }

    override var isFinished: Bool { false }
    override var isCancelled: Bool { false }
    override var fractionCompleted: Double { 0 }
    override var isIndeterminate: Bool { true }
}
#endif
