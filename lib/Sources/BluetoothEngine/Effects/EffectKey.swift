import Foundation

struct EffectKey: Hashable {
    let id: Int

    init(name: EffectName, _ items: any Hashable...) {
        var hasher = Hasher()
        hasher.combine(name)
        for item in items {
            hasher.combine(item)
        }
        self.id = hasher.finalize()
    }
}
