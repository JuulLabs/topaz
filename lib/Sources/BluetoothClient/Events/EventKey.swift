import Foundation

public struct EventKey: Sendable, Hashable {
    let id: Int

    init(name: EventName, _ items: any Hashable...) {
        var hasher = Hasher()
        hasher.combine(name)
        for item in items {
            hasher.combine(item)
        }
        self.id = hasher.finalize()
    }
}
