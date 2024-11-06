import Foundation

public func mapNotifications<T>(
    name: Notification.Name,
    center: NotificationCenter = .default,
    transform: @escaping @Sendable @MainActor (Notification) -> T
) -> AsyncMapSequence<NotificationCenter.Notifications, T> {
    center.notifications(named: name).map(transform)
}

public func compactMapNotifications<T>(
    name: Notification.Name,
    center: NotificationCenter = .default,
    transform: @escaping @Sendable @MainActor (Notification) -> T?
) -> AsyncCompactMapSequence<NotificationCenter.Notifications, T> {
    center.notifications(named: name).compactMap(transform)
}
