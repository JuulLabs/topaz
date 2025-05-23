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

struct PromiseStore<Result: Sendable> {

    private var promises: [AnyHashable: [CheckedContinuation<Result, any Error>]] = [:]

    mutating func register(_ continuation: CheckedContinuation<Result, any Error>, with key: AnyHashable) {
        if promises[key] == nil {
            promises[key] = []
        }
        promises[key]?.append(continuation)
    }

    mutating func resolve(with value: Result, for key: AnyHashable) {
        guard let continuations = promises.removeValue(forKey: key) else {
            return
        }
        continuations.forEach { $0.resume(returning: value) }
    }

    mutating func reject(with error: any Error, for key: AnyHashable) {
        guard let continuations = promises.removeValue(forKey: key) else {
            return
        }
        continuations.forEach { $0.resume(throwing: error) }
    }

    mutating func rejectAll(with error: any Error) {
        promises.values.forEach { continuations in
            continuations.forEach { $0.resume(throwing: error) }
        }
        promises = [:]
    }

    mutating func resolve<T: Hashable>(with value: Result, where predicate: (T) -> Bool) {
        promises.keys
            .compactMap { $0 as? T }
            .filter(predicate)
            .forEach { resolve(with: value, for: $0) }
    }

    mutating func reject<T: Hashable>(with error: any Error, where predicate: (T) -> Bool) {
        promises.keys
            .compactMap { $0 as? T }
            .filter(predicate)
            .forEach { reject(with: error, for: $0) }
    }
}
