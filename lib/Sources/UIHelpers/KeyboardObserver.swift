import Foundation
import Helpers
import Observation
import UIKit

@MainActor
@Observable
public final class KeyboardObserver {
    public var frame: CGRect?

    public init() {
        Task { [weak self] in
            for await newFrame in KeyboardObserver.keyboardWillShowNotifications() {
                self?.frame = newFrame
            }
        }
        Task { [weak self] in
            for await _ in KeyboardObserver.keyboardWillHideNotifications() {
                self?.frame = nil
            }
        }
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
