import Downloader
import Foundation
import OSLog
import WebKit

private let log = Logger(subsystem: "WebView", category: "DownloadDelegate")

extension NavigationEngine: WKDownloadDelegate {

    public func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String) async -> URL? {
        let filename = suggestedFilename.isEmpty ? "download" : suggestedFilename
        let destination = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: destination)
        log.debug("Download started: \(download) url=\(response.url?.absoluteString ?? "<unknown>") destination=\(destination.path)")
        Downloads.shared.beginDownload(url: destination, for: download)
        delegate?.startedDownload(for: destination)
        return destination
    }

    public func downloadDidFinish(_ download: WKDownload) {
        log.debug("Download finished: \(download)")
        guard let url = Downloads.shared.finishDownload(for: download) else {
            log.warning("Out-of-band download finish ignored download=\(download)")
            return
        }
        delegate?.completedDownload(for: url)
    }

    public func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        log.warning("Download failed: \(download) error=\(error)")
        Downloads.shared.cancelDownload(for: download, with: error)
    }
}
