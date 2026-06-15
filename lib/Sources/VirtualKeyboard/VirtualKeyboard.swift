import Foundation
import JsMessage
import Observation
import OSLog
import UIHelpers
import UIKit

private let logger = Logger(subsystem: "Topaz", category: "VirtualKeyboard")

/**
 * https://www.w3.org/TR/virtual-keyboard/#the-virtualkeyboard-interface
 *
 * This processor bridges the virtual keyboard API from the Js context to a SwiftUI view model.
 * On keyboard transition we forward the geometry change over to Js. When the show/hide or
 * overlaysContent setter is invoked from Js, we forward the activity to the view model.
 */
public final actor VirtualKeyboard: DispatchingJsMessageProcessor {

    public enum Action: String, JsMessageAction {
        case setOverlaysContent
        case show
    }

    public static let handlerName = "keyboard"
    public let enableDebugLogging: Bool
    public let messageLog: JsMessageLog

    private let viewModel: VirtualKeyboardModel
    private var task: Task<Void, Never>?

    public init(
        viewModel: VirtualKeyboardModel,
        enableDebugLogging: Bool = false
    ) {
        self.viewModel = viewModel
        self.enableDebugLogging = enableDebugLogging
        self.messageLog = JsMessageLog(logger: logger, enabled: enableDebugLogging)
    }

    public func didAttach(to context: JsContext) async {
        task = Task { @MainActor in
            let observer = KeyboardObserver()
            for await frame in observer.stream() {
                guard !Task.isCancelled else { break }
                let adjustedFrame = adjustedKeyboardBoundingRect(globalFrame: frame)
                let event = GeometryChange(frame: adjustedFrame).toJs(targetId: "keyboard")
                _ = await context.sendEvent(event)
                messageLog.logEvent(event)
            }
            observer.endStream()
        }
    }

    public func didDetach(from context: JsContext) async {
        task?.cancel()
        task = nil
        await MainActor.run {
            viewModel.overlaysContent = false
        }
    }

    public func handle(_ message: JsActionMessage<Action>) async throws -> JsMessageResponse {
        switch message.action {
        case .setOverlaysContent:
            await setOverlaysContentAction(messageData: message.bodyData)
        case .show:
            await showOrHideAction(messageData: message.bodyData)
        }
    }

    private func setOverlaysContentAction(messageData: [String: JsType]?) async -> JsMessageResponse {
        guard let enable = messageData?["enable"]?.number?.boolValue else {
            return .error(JsMessageError.badRequest.toDomError())
        }
        await MainActor.run {
            viewModel.overlaysContent = enable
        }
        return .body([:])
    }

    private func showOrHideAction(messageData: [String: JsType]?) async -> JsMessageResponse {
        guard let show = messageData?["show"]?.number?.boolValue else {
            return .error(JsMessageError.badRequest.toDomError())
        }
        await MainActor.run {
            if show {
                viewModel.onShow()
            } else {
                viewModel.onHide()
            }
        }
        return .body([:])
    }

    /**
     * We assume here that the enclosing webview is respecting the safe area insets in which case we need to
     * adjust the keyboard frame from global view coordinates to webview coordinate space.
     * We move the y origin _up_ to account for the top insets. And we _subtract_ the bottom insets from the height
     * in case the web page is using the height-from-bottom-of-container as its guide.
     */
    @MainActor
    private func adjustedKeyboardBoundingRect(globalFrame: CGRect?) -> CGRect {
        guard let globalFrame, let window = window() else { return .zero }
        let localFrame = CGRect(
            x: globalFrame.origin.x,
            y: globalFrame.origin.y - window.safeAreaInsets.top,
            width: globalFrame.width,
            height: globalFrame.height - window.safeAreaInsets.bottom
        )
        return localFrame
    }

    @MainActor
    private func window() -> UIWindow? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        return scene?.windows.first
    }
}
