import Foundation
import JsMessage
import Observation
import OSLog
import UIHelpers
import UIKit

private let messageLog = Logger(subsystem: "VirtualKeyboard", category: "Message")

/**
 * https://www.w3.org/TR/virtual-keyboard/#the-virtualkeyboard-interface
 *
 * This processor bridges the virtual keyboard API from the Js context to a SwiftUI view model.
 * On keyboard transition we forward the geometry change over to Js. When the show/hide or
 * overlaysContent setter is invoked from Js, we forward the activity to the view model.
 */
public final actor VirtualKeyboard: JsMessageProcessor {
    public static let handlerName = "keyboard"
    public let enableDebugLogging: Bool

    private let viewModel: VirtualKeyboardModel
    private var task: Task<Void, Never>?

    public init(
        viewModel: VirtualKeyboardModel,
        enableDebugLogging: Bool = false
    ) {
        self.viewModel = viewModel
        self.enableDebugLogging = enableDebugLogging
    }

    public func didAttach(to context: JsContext) async {
        task = Task { @MainActor in
            let observer = KeyboardObserver()
            for await frame in observer.stream() {
                guard !Task.isCancelled else { break }
                let adjustedFrame = adjustedKeyboardBoundingRect(globalFrame: frame)
                let event = GeometryChange(frame: adjustedFrame).toJs(targetId: "keyboard")
                _ = await context.sendEvent(event)
                await logJsEvent(event: event)
            }
            observer.endStream()
        }
    }

    public func didDetach(from context: JsContext) async {
        task?.cancel()
        task = nil
        /* TODO: disabled due to race condition between WebView instances - done in the Coordinator instead
         await MainActor.run {
         // Important to reset back to the default state
         viewModel.overlaysContent = false
         }
         */
    }

    public func process(request: JsMessageRequest, in context: JsContext) async -> JsMessageResponse {
        var actionForFailureLogging: Message.Action?
        do {
            let message = try request.extractMessage().get()
            actionForFailureLogging = message.action
            logRequest(message: message)
            let response = try await processAction(message: message)
            logResponse(action: message.action, response: response)
            return response
        } catch {
            let response = JsMessageResponse.error(error.toDomError())
            logResponse(action: actionForFailureLogging, response: response)
            return response
        }
    }

    private func processAction(message: Message) async throws -> JsMessageResponse {
        switch message.action {
        case .setOverlaysContent:
            await setOverlaysContentAction(messageData: message.bodyData)
        case .show:
            await showOrHideAction(messageData: message.bodyData)
        }
    }

    private func setOverlaysContentAction(messageData: [String: JsType]?) async -> JsMessageResponse {
        guard let enable = messageData?["enable"]?.number?.boolValue else {
            return .error(VirtualKeyboardError.badRequest.toDomError())
        }
        await MainActor.run {
            viewModel.overlaysContent = enable
        }
        return .body([:])
    }

    private func showOrHideAction(messageData: [String: JsType]?) async -> JsMessageResponse {
        guard let show = messageData?["show"]?.number?.boolValue else {
            return .error(VirtualKeyboardError.badRequest.toDomError())
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

    private func logRequest(message: Message) {
        guard enableDebugLogging else { return }
        messageLog.debug("Request \(message.action.rawValue, privacy: .public): \(JsType.dictionaryAsString(message.bodyData), privacy: .public)")
    }

    private func logResponse(action: Message.Action?, response: JsMessageResponse) {
        guard enableDebugLogging else { return }
        let actionString = action?.rawValue ?? "?"
        switch response {
        case let .body(body):
            messageLog.debug("Response \(actionString, privacy: .public): \(body.asDebugString(), privacy: .public)")
        case let .error(error):
            messageLog.error("Response \(actionString, privacy: .public): \(error.jsRepresentation, privacy: .public)")
        }
    }

    private func logJsEvent(event: JsEvent) {
        guard enableDebugLogging else { return }
        messageLog.debug("Event: \(event.asDebugString(), privacy: .public)")
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
