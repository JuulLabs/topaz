@testable import EventBus
import Foundation

struct FakeError: Error, Equatable {}

struct TestEventOne: BluetoothEvent, Equatable {
    let id: String
    let lookup: EventLookup

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

struct TestEventTwo: BluetoothEvent, Equatable {
    let id: String
    let lookup: EventLookup

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
