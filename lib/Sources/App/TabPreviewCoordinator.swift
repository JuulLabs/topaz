import Foundation
import Helpers
import Tabs
import WebView

/// Captures and stores the tab-grid thumbnails.
///
/// A tab's first thumbnail is captured as soon as its page finishes loading, because
/// there is nothing to churn against while the cell is empty. Later loads are collapsed
/// onto a trailing timer per tab, so a page that reloads itself in a loop cannot spam
/// snapshots, and cannot starve any other tab either. Leaving a tab, and sending the app
/// to the background, capture at once and cancel that tab's pending timer.
@MainActor
final class TabPreviewCoordinator {
    static let debounceInterval: Duration = .seconds(10)

    private let store: TabPreviewStore
    private let format: PagePreviewFormat
    private let debounceInterval: Duration
    private var debouncers: [UUID: Debouncer] = [:]
    private var captures: [UUID: Task<Void, Never>] = [:]
    private var capturedTabs: Set<UUID> = []

    /// Called on the main actor after a new thumbnail is stored for a tab.
    var onPreviewStored: (UUID) -> Void = { _ in }

    init(
        store: TabPreviewStore,
        format: PagePreviewFormat = PagePreviewFormat(
            width: TabPreviewMetrics.width,
            aspectRatio: TabPreviewMetrics.aspectRatio
        ),
        debounceInterval: Duration = TabPreviewCoordinator.debounceInterval
    ) {
        self.store = store
        self.format = format
        self.debounceInterval = debounceInterval
    }

    /// The page finished loading. Captures now if this tab has no thumbnail yet,
    /// otherwise waits out the debounce interval.
    func pageDidLoad(tabID: UUID, page: any PagePreviewCapturing) {
        guard capturedTabs.contains(tabID) else {
            capture(tabID: tabID, page: page)
            return
        }
        let debouncer = debouncers[tabID] ?? Debouncer()
        debouncers[tabID] = debouncer
        Task {
            await debouncer.debounce(interval: debounceInterval) { @MainActor [weak self, weak page] in
                guard let self, let page else { return }
                capture(tabID: tabID, page: page)
            }
        }
    }

    /// Captures immediately, superseding any pending debounced capture for the tab.
    func captureNow(tabID: UUID, page: any PagePreviewCapturing) {
        takePending(for: tabID)
        capture(tabID: tabID, page: page)
    }

    func removePreview(for tabID: UUID) {
        let pending = takePending(for: tabID)
        capturedTabs.remove(tabID)
        Task {
            await pending?.value
            await store.remove(for: tabID)
        }
    }

    func removeAllPreviews() {
        let pending = Set(debouncers.keys).union(captures.keys).compactMap { takePending(for: $0) }
        capturedTabs.removeAll()
        Task {
            for capture in pending {
                await capture.value
            }
            await store.removeAll()
        }
    }

    func loadPreview(for tabID: UUID) async -> Data? {
        let data = await store.load(for: tabID)
        if data != nil {
            capturedTabs.insert(tabID)
        }
        return data
    }

    /// Stops the tab's pending timer and cancels any snapshot already in flight,
    /// returning that capture so a removal can be ordered after it has finished — a
    /// snapshot awaiting WebKit must not write a thumbnail that was just removed.
    @discardableResult
    private func takePending(for tabID: UUID) -> Task<Void, Never>? {
        if let debouncer = debouncers.removeValue(forKey: tabID) {
            Task {
                await debouncer.cancel()
            }
        }
        let capture = captures.removeValue(forKey: tabID)
        capture?.cancel()
        return capture
    }

    /// A failed snapshot or a failed write leaves the previous thumbnail in place, and
    /// leaves the tab uncaptured so the next load captures it immediately rather than
    /// waiting out the debounce. Another capture follows on the next load, tab exit or
    /// backgrounding.
    private func capture(tabID: UUID, page: any PagePreviewCapturing) {
        captures[tabID]?.cancel()
        captures[tabID] = Task {
            guard let data = await page.capturePreview(format: format), !Task.isCancelled else {
                return
            }
            guard await store.save(data, for: tabID), !Task.isCancelled else { return }
            capturedTabs.insert(tabID)
            onPreviewStored(tabID)
        }
    }
}
