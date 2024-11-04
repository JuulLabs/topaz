import Foundation

/*
 A note about an efficiency choice we could make here. Currently we are
 using UUID as a string to bridge object identities between CoreBluetooth
 and Web BLE for peripherals, characteristics, etc. So every round trip
 message has to parse the string from Javascript into a UUID, and then
 we use UUID as the hash value here and elsewhere to lookup stored state,
 and then in the reply we have to re-serialize the UUID as a string.

 We could cut down the busy work in a couple of ways:
 1. keep the string around to skip the re-serialization in the reply
 2. instead of UUID, generate a "hash" integer (it can just be in dumb
 incrementer but an actual hash is probably ideal) and send the integer
 in the requests with the UUID. Then use this as the hash for lookup
 tables. This would avoid both the de-serialization and the hashing
 function on the UUID.

 For basic interactions this won't matter, but for read/write of any
 significant amount of data we may need some speedups.
 */

struct PromiseRegistry {
    private struct Key: Hashable {
        let uuid: UUID
        let action: Message.Action
    }

    private var pendingPromises: [Key: [PendingAction<Void>]] = [:]

    mutating func register(_ action: Message.Action, for id: UUID) -> PendingAction<Void> {
        let key = Key(uuid: id, action: action)
        if pendingPromises[key] == nil {
            pendingPromises[key] = []
        }
        let promise = PendingAction<Void>()
        pendingPromises[key]?.append(promise)
        return promise
    }

    mutating func resolve(_ action: Message.Action, for id: UUID, with error: (any Error)? = nil) {
        let key = Key(uuid: id, action: action)
        guard let promises = pendingPromises.removeValue(forKey: key) else {
            return
        }
        promises.forEach { $0.resolve(with: (), orRejectIf: error) }
    }

    mutating func rejectAll(with error: any Error) {
        pendingPromises.values.forEach { promises in
            promises.forEach { $0.reject(with: error) }
        }
        pendingPromises = [:]
    }
}
