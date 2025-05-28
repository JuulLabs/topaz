import Foundation

struct ListenerStore<Value: Sendable> {
    struct Listener {
        let block: @Sendable (Value) async -> Void
    }

    private var listeners: [AnyHashable: [@Sendable (Value) async -> Void]] = [:]

    mutating func attach(
        key: AnyHashable,
        block: @Sendable @escaping (Value) async -> Void
    ) {
        if listeners[key] == nil {
            listeners[key] = []
        }
        listeners[key]?.append(block)
    }

    mutating func detach(key: AnyHashable) {
        listeners.removeValue(forKey: key)
    }

    mutating func detachAll() {
        listeners = [:]
    }

    func getListeners(forKey key: AnyHashable) -> [@Sendable (Value) async -> Void] {
        listeners[key] ?? []
    }

    func getListeners<T: Hashable>(where predicate: (T) -> Bool) -> [@Sendable (Value) async -> Void] {
        listeners.reduce(into: []) { blocks, entry in
            if let key = entry.key as? T, predicate(key) {
                blocks += entry.value
            }
        }
    }

    mutating func detachListeners(forKey key: AnyHashable) -> [@Sendable (Value) async -> Void] {
        listeners.removeValue(forKey: key) ?? []
    }

    mutating func detachListeners<T: Hashable>(where predicate: (T) -> Bool) -> [@Sendable (Value) async -> Void] {
        var result: [@Sendable (Value) async -> Void] = []
        let keys = listeners.keys
            .compactMap { $0 as? T }
            .filter(predicate)
        for key in keys {
            if let blocks = listeners.removeValue(forKey: key) {
                result += blocks
            }
        }
        return result
    }
}
