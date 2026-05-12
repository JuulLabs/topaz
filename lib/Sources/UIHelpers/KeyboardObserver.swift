import Foundation
import Helpers
import Observation
import UIKit

@MainActor
@Observable
public final class KeyboardObserver {
    public var frame: CGRect?

    private var continuation: AsyncStream<CGRect?>.Continuation?
    private var tasks: [Task<Void, Never>] = []

    public init() {
        tasks.append(Task { [weak self] in
            for await newFrame in KeyboardObserver.keyboardWillShowNotifications() {
                self?.frame = newFrame
                self?.continuation?.yield(newFrame)
            }
        })
        tasks.append(Task { [weak self] in
            for await _ in KeyboardObserver.keyboardWillHideNotifications() {
                self?.frame = nil
                self?.continuation?.yield(nil)
            }
        })
    }

    isolated deinit {
        endStream()
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
    }

    public func stream() -> AsyncStream<CGRect?> {
        precondition(continuation == nil, "KeyboardObserver does not support multiple subscribers")
        let (stream, continuation) = AsyncStream<CGRect?>.makeStream()
        self.continuation = continuation
        return stream
    }

    public func endStream() {
        continuation?.finish()
        continuation = nil
    }

    private static func keyboardWillShowNotifications() -> AsyncCompactMapSequence<NotificationCenter.Notifications, CGRect> {
        NotificationCenter.default
            .notifications(named: UIResponder.keyboardWillShowNotification)
            .compactMap { notification in
                notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            }
    }

    private static func keyboardWillHideNotifications() -> AsyncMapSequence<NotificationCenter.Notifications, Void> {
        NotificationCenter.default
            .notifications(named: UIResponder.keyboardWillHideNotification)
            .map { _ in () }
    }
}
