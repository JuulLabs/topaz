import Bluetooth
@testable import BluetoothMessage
import Foundation
import Helpers
import Testing

extension Tag {
    @Tag static var bluetoothState: Self
}

@Suite(.tags(.bluetoothState))
struct BluetoothStateTests {

    private let storage: InMemoryStorage
    private let sut: BluetoothState

    init() {
        storage = InMemoryStorage()
        sut = BluetoothState(store: storage)
    }

    @Test
    func rememberPeripheral_noExistingPersistedPeripherals_storesPeripheralId() async {
        await #expect(throws: Never.self) {
            await sut.rememberPeripheral(identifier: UUID(n: 1))

            let result: [UUID] = try await storage.load(for: .uuidsKey)

            #expect(result.count == 1)
            #expect(result.first == UUID(n: 1))
        }
    }

    @Test
    func rememberPeripheral_storeHasExistingPeripherals_storesPeripheralIdWithoutLosingExistingIds() async {
        await #expect(throws: Never.self) {
            try await storage.save([UUID(n: 1)], for: .uuidsKey)

            await sut.rememberPeripheral(identifier: UUID(n: 2))

            let result: [UUID] = try await storage.load(for: .uuidsKey)

            #expect(result.count == 2)
            #expect(result.contains { $0 == UUID(n: 1) })
            #expect(result.contains { $0 == UUID(n: 2) })
        }
    }

    @Test
    func rememberPeripheral_storeHasPeripheralThatsBeingAdded_duplicateEntryIsNotAdded() async {
        await #expect(throws: Never.self) {
            try await storage.save([UUID(n: 1)], for: .uuidsKey)

            await sut.rememberPeripheral(identifier: UUID(n: 1))

            let result: [UUID] = try await storage.load(for: .uuidsKey)

            #expect(result.count == 1)
            #expect(result.contains { $0 == UUID(n: 1) })
        }
    }

    @Test
    func forgetPeripheral_storeHasPeripheralToForget_entryIsRemoved() async {
        await #expect(throws: Never.self) {
            try await storage.save([UUID(n: 1), UUID(n: 2)], for: .uuidsKey)

            await sut.forgetPeripheral(identifier: UUID(n: 1))

            let result: [UUID] = try await storage.load(for: .uuidsKey)

            #expect(result.count == 1)
            #expect(result.contains { $0 == UUID(n: 2) })
        }
    }

    @Test
    func forgetPeripheral_storeDoesNotHavePeripheralToForget_storeDoesNotChange() async {
        await #expect(throws: Never.self) {
            try await storage.save([UUID(n: 2), UUID(n: 7)], for: .uuidsKey)

            await sut.forgetPeripheral(identifier: UUID(n: 1))

            let result: [UUID] = try await storage.load(for: .uuidsKey)

            #expect(result.count == 2)
            #expect(result.contains { $0 == UUID(n: 2) })
            #expect(result.contains { $0 == UUID(n: 7) })
        }
    }

    @Test
    func forgetPeripherals_storeDoesNotHavePeripheralsToForget_storeDoesNotChange() async {
        await #expect(throws: Never.self) {
            try await storage.save([UUID(n: 2), UUID(n: 7)], for: .uuidsKey)

            await sut.forgetPeripherals(identifiers: [UUID(n: 1), UUID(n: 3)])

            let result: [UUID] = try await storage.load(for: .uuidsKey)

            #expect(result.count == 2)
            #expect(result.contains { $0 == UUID(n: 2) })
            #expect(result.contains { $0 == UUID(n: 7) })
        }
    }

    @Test
    func forgetPeripherals_1IdToForgetInStore_removesPeripheralId() async {
        await #expect(throws: Never.self) {
            try await storage.save([UUID(n: 2), UUID(n: 7)], for: .uuidsKey)

            await sut.forgetPeripherals(identifiers: [UUID(n: 2)])

            let result: [UUID] = try await storage.load(for: .uuidsKey)

            #expect(result.count == 1)
            #expect(result.contains { $0 == UUID(n: 7) })
        }
    }

    @Test
    func forgetPeripherals_MultipleIdsToForgetInStore_removesPeripheralIds() async {
        await #expect(throws: Never.self) {
            try await storage.save([UUID(n: 2), UUID(n: 7)], for: .uuidsKey)

            await sut.forgetPeripherals(identifiers: [UUID(n: 7), UUID(n: 2)])

            let result: [UUID] = try await storage.load(for: .uuidsKey)

            #expect(result.count == 0)
        }
    }

    @Test
    func getKnownPeripheralIdentifiers_storeHasPeripherals_returnsCorrectIds() async {
        await #expect(throws: Never.self) {
            try await storage.save([UUID(n: 7), UUID(n: 3), UUID(n: 5), UUID(n: 1)], for: .uuidsKey)

            let result = await sut.getKnownPeripheralIdentifiers()

            #expect(result.count == 4)
            #expect(result.contains { $0 == UUID(n: 7) })
            #expect(result.contains { $0 == UUID(n: 3) })
            #expect(result.contains { $0 == UUID(n: 5) })
            #expect(result.contains { $0 == UUID(n: 1) })
        }
    }

    @Test
    func getKnownPeripheralIdentifiers_storeHasNothing_EmptySetReturned() async {
        await #expect(throws: Never.self) {
            let result = await sut.getKnownPeripheralIdentifiers()

            #expect(result.count == 0)
        }
    }

    @Test
    func putPeripheral_withoutReplaceWhenEmpty_storesPeripheral() async throws {
        let uuid0 = UUID(n: 0)
        let original = FakePeripheral(id: uuid0)
        #expect(await sut.peripherals.isEmpty)
        await sut.putPeripheral(original, replace: false)
        let fetched = try await sut.getPeripheral(uuid0)
        #expect(fetched.objId == original.objId)
    }

    @Test
    func putPeripheral_withReplaceWhenEmpty_storesPeripheral() async throws {
        let uuid0 = UUID(n: 0)
        let original = FakePeripheral(id: uuid0)
        #expect(await sut.peripherals.isEmpty)
        await sut.putPeripheral(original, replace: true)
        let fetched = try await sut.getPeripheral(uuid0)
        #expect(fetched.objId == original.objId)
    }

    @Test
    func putPeripheral_withoutReplaceWhenExists_doesNotOverwrite() async throws {
        let uuid0 = UUID(n: 0)
        let original = FakePeripheral(id: uuid0)
        let replacement = FakePeripheral(id: uuid0)
        await sut.putPeripheral(original, replace: false)
        await sut.putPeripheral(replacement, replace: false)
        let fetched = try await sut.getPeripheral(uuid0)
        #expect(fetched.objId == original.objId)
    }

    @Test
    func putPeripheral_withReplaceWhenExists_overwrites() async throws {
        let uuid0 = UUID(n: 0)
        let original = FakePeripheral(id: uuid0)
        let replacement = FakePeripheral(id: uuid0)
        await sut.putPeripheral(original, replace: true)
        await sut.putPeripheral(replacement, replace: true)
        let fetched = try await sut.getPeripheral(uuid0)
        #expect(fetched.objId == replacement.objId)
    }
}

fileprivate extension String {
    static let uuidsKey = "savedPeripheralUUIDs"
}

fileprivate extension Peripheral {
    /// The unique instance id of the wrapped peripheral object
    var objId: ObjectIdentifier {
        ObjectIdentifier(peripheral.wrapped.unsafeObject)
    }
}
