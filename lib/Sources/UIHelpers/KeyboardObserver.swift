import Foundation
import Helpers
import Observation
import UIKit

@MainActor
@Observable
public final class KeyboardObserver {
    public var frame: CGRect?

    public init() {
        Task {
            Task { [weak self] in
                for await newFrame in compactMapNotifications(
                    name: UIResponder.keyboardWillShowNotification,
                    transform: KeyboardObserver.extractKeyboardFrame
                ) {
                    self?.frame = newFrame
                }
            }
            Task { [weak self] in
                for await _ in mapNotifications(
                    name: UIResponder.keyboardWillHideNotification,
                    transform: { _ in 0 }
                ) {
                    self?.frame = nil
                }
            }
        }
    }

    private static func extractKeyboardFrame(from notification: Notification) -> CGRect? {
        notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
    }
}
