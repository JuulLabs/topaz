import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
public final class Downloads {
    private var nextId: Int = 0
    private var cache: [ObjectIdentifier: DownloadRowModel] = [:]

    var downloads: [DownloadRowModel] {
        cache.values.sorted(by: orderByIdDescending)
    }

    public func beginDownload(url: URL, for progressReporting: ProgressReporting) {
        let download = DownloadRowModel(id: nextId, destinationURL: url)
        nextId += 1
        withAnimation {
            cache[ObjectIdentifier(progressReporting)] = download
        }
        Task {
            await download.trackUpdates(using: progressReporting)
        }
    }

    @discardableResult
    public func finishDownload(for progressReporting: ProgressReporting) -> URL? {
        guard let download = cache[ObjectIdentifier(progressReporting)] else {
            return nil
        }
        download.progressObserver?.finish(finalProgress: progressReporting.progress)
        return download.destinationURL
    }

    public func cancelDownload(for progressReporting: ProgressReporting, with error: Error) {
        guard let download = cache[ObjectIdentifier(progressReporting)] else {
            return
        }
        download.setFailed(error)
    }

    func delete(indexSet: IndexSet) {
        let idsToDelete = zip(downloads.indices, downloads)
            .filter { (index, _) in indexSet.contains(index) }
            .map { (_, download) in download.id }
        withAnimation {
            cache = cache.filter { (_, download) in
                !idsToDelete.contains(download.id)
            }
        }
    }

    public var isEmpty: Bool {
        cache.isEmpty
    }
}

extension Downloads {
    public static let shared: Downloads = .init()
}

private func orderByIdDescending(_ lhs: DownloadRowModel, _ rhs: DownloadRowModel) -> Bool {
    lhs.id > rhs.id
}
