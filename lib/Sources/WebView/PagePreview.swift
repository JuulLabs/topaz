import OSLog
import UIKit
import WebKit

private let log = Logger(subsystem: "Topaz", category: "PagePreview")

/// A page that can render itself as a tab-grid thumbnail.
@MainActor
public protocol PagePreviewCapturing: AnyObject {
    func capturePreview(format: PagePreviewFormat) async -> Data?
}

/// Thumbnail geometry and encoding for a captured page preview.
public struct PagePreviewFormat: Sendable {
    /// Width in points. WebKit downscales the snapshot to this width, and the resulting
    /// image carries the device's pixel scale.
    public let width: CGFloat
    /// Width over height of the captured slice.
    public let aspectRatio: CGFloat
    public let compressionQuality: CGFloat

    public init(width: CGFloat, aspectRatio: CGFloat, compressionQuality: CGFloat = 0.8) {
        self.width = width
        self.aspectRatio = aspectRatio
        self.compressionQuality = compressionQuality
    }
}

/// Renders the top of whatever the web view is currently showing, without scrolling it,
/// as a thumbnail-sized JPEG. Returns nil when the page cannot be rendered.
@MainActor
func capturePagePreview(from webView: WKWebView, format: PagePreviewFormat) async -> Data? {
    let bounds = webView.bounds
    guard bounds.width > 0, bounds.height > 0 else { return nil }
    let configuration = WKSnapshotConfiguration()
    configuration.rect = CGRect(
        origin: .zero,
        size: CGSize(width: bounds.width, height: min(bounds.width / format.aspectRatio, bounds.height))
    )
    configuration.snapshotWidth = NSNumber(value: format.width)
    do {
        let image = try await webView.takeSnapshot(configuration: configuration)
        return flattened(image).jpegData(compressionQuality: format.compressionQuality)
    } catch {
        log.error("Unable to capture page preview: \(error.localizedDescription, privacy: .public)")
        return nil
    }
}

/// Redraws a snapshot without its alpha channel. WebKit always hands back a premultiplied
/// alpha image, which JPEG cannot store: ImageIO logs a warning and doubles the memory
/// needed to decode the file.
@MainActor
private func flattened(_ image: UIImage) -> UIImage {
    let rendererFormat = UIGraphicsImageRendererFormat.preferred()
    rendererFormat.opaque = true
    rendererFormat.scale = image.scale
    let renderer = UIGraphicsImageRenderer(size: image.size, format: rendererFormat)
    return renderer.image { context in
        UIColor.white.setFill()
        context.fill(CGRect(origin: .zero, size: image.size))
        image.draw(at: .zero)
    }
}
