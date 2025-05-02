@testable import SecurityList
import Foundation
import TestHelpers
import Testing

private struct BlockedUuids {
    let blockedForReading: UUID
    let blockedForWriting: UUID
    let blockedForAny: UUID
    let all: [UUID]

    init(read: UUID, write: UUID, any: UUID) {
        blockedForReading = read
        blockedForWriting = write
        blockedForAny = any
        all = [read, write, any]
    }
}

private struct NamedUuids: Sendable {
    let unlisted = UUID(n: 0)
    let services = BlockedUuids(read: UUID(n: 10), write: UUID(n: 11), any: UUID(n: 12))
    let characteristics = BlockedUuids(read: UUID(n: 20), write: UUID(n: 21), any: UUID(n: 22))
    let descriptors = BlockedUuids(read: UUID(n: 30), write: UUID(n: 31), any: UUID(n: 32))
}

// Declared outside the test struct so we can reference them in test argument constructors
private let uuids = NamedUuids()

@Suite
struct SecurityListTests {
    private let sut: SecurityList

    init() {
        sut = SecurityList(
            services: [
                uuids.services.blockedForReading: .reading,
                uuids.services.blockedForWriting: .writing,
                uuids.services.blockedForAny: .any,
            ],
            characteristics: [
                uuids.characteristics.blockedForReading: .reading,
                uuids.characteristics.blockedForWriting: .writing,
                uuids.characteristics.blockedForAny: .any,
            ],
            descriptors: [
                uuids.descriptors.blockedForReading: .reading,
                uuids.descriptors.blockedForWriting: .writing,
                uuids.descriptors.blockedForAny: .any,
            ]
        )
    }

    @Test(arguments: SecurityList.Operation.allCases, SecurityList.Group.allCases)
    func isBlocked_withUnlistedUuid_isAlwaysFalse(operation: SecurityList.Operation, group: SecurityList.Group) {
        #expect(sut.isBlocked(uuids.unlisted, in: group, for: operation) == false)
    }

    // MARK: - Services

    @Test
    func isBlocked_withServiceUuidBlockedForReading_isTrueForServicesReadOrAny() {
        #expect(sut.isBlocked(uuids.services.blockedForReading, in: .services, for: .reading) == true)
        #expect(sut.isBlocked(uuids.services.blockedForReading, in: .services, for: .any) == true)
    }

    @Test
    func isBlocked_withServiceUuidBlockedForReading_isFalseForServicesWrite() {
        #expect(sut.isBlocked(uuids.services.blockedForReading, in: .services, for: .writing) == false)
    }

    @Test
    func isBlocked_withServiceUuidBlockedForWriting_isTrueForServicesWriteOrAny() {
        #expect(sut.isBlocked(uuids.services.blockedForWriting, in: .services, for: .writing) == true)
        #expect(sut.isBlocked(uuids.services.blockedForWriting, in: .services, for: .any) == true)
    }

    @Test
    func isBlocked_withServiceUuidBlockedForWriting_isFalseForServicesRead() {
        #expect(sut.isBlocked(uuids.services.blockedForWriting, in: .services, for: .reading) == false)
    }

    @Test(arguments: SecurityList.Operation.allCases)
    func isBlocked_withServiceUuidBlockedForAny_isAlwaysTrueForServices(operation: SecurityList.Operation) {
        #expect(sut.isBlocked(uuids.services.blockedForAny, in: .services, for: operation) == true)
    }

    @Test(arguments: uuids.services.all, SecurityList.Operation.allCases)
    func isBlocked_withAllServiceUuidsOnBlocklist_isFalseForCharacteristicAndDescriptorGroups(uuid: UUID, operation: SecurityList.Operation) {
        #expect(sut.isBlocked(uuid, in: .characteristics, for: operation) == false)
        #expect(sut.isBlocked(uuid, in: .descriptors, for: operation) == false)
    }

    // MARK: - Characteristics

    @Test
    func isBlocked_withCharacteristicUuidBlockedForReading_isTrueForCharacteristicsReadOrAny() {
        #expect(sut.isBlocked(uuids.characteristics.blockedForReading, in: .characteristics, for: .reading) == true)
        #expect(sut.isBlocked(uuids.characteristics.blockedForReading, in: .characteristics, for: .any) == true)
    }

    @Test
    func isBlocked_withCharacteristicUuidBlockedForReading_isFalseForCharacteristicsWrite() {
        #expect(sut.isBlocked(uuids.characteristics.blockedForReading, in: .characteristics, for: .writing) == false)
    }

    @Test
    func isBlocked_withCharacteristicUuidBlockedForWriting_isTrueForCharacteristicsWriteOrAny() {
        #expect(sut.isBlocked(uuids.characteristics.blockedForWriting, in: .characteristics, for: .writing) == true)
        #expect(sut.isBlocked(uuids.characteristics.blockedForWriting, in: .characteristics, for: .any) == true)
    }

    @Test
    func isBlocked_withCharacteristicUuidBlockedForWriting_isFalseForCharacteristicsRead() {
        #expect(sut.isBlocked(uuids.characteristics.blockedForWriting, in: .characteristics, for: .reading) == false)
    }

    @Test(arguments: SecurityList.Operation.allCases)
    func isBlocked_withCharacteristicUuidBlockedForAny_isAlwaysTrueForCharacteristics(operation: SecurityList.Operation) {
        #expect(sut.isBlocked(uuids.characteristics.blockedForAny, in: .characteristics, for: operation) == true)
    }

    @Test(arguments: uuids.characteristics.all, SecurityList.Operation.allCases)
    func isBlocked_withAllCharacteristicUuidsOnBlocklist_isFalseForServiceAndDescriptorGroups(uuid: UUID, operation: SecurityList.Operation) {
        #expect(sut.isBlocked(uuid, in: .services, for: operation) == false)
        #expect(sut.isBlocked(uuid, in: .descriptors, for: operation) == false)
    }

    // MARK: - Descriptors

    @Test
    func isBlocked_withDescriptorUuidBlockedForReading_isTrueForDescriptorsReadOrAny() {
        #expect(sut.isBlocked(uuids.descriptors.blockedForReading, in: .descriptors, for: .reading) == true)
        #expect(sut.isBlocked(uuids.descriptors.blockedForReading, in: .descriptors, for: .any) == true)
    }

    @Test
    func isBlocked_withDescriptorUuidBlockedForReading_isFalseForDescriptorsWrite() {
        #expect(sut.isBlocked(uuids.descriptors.blockedForReading, in: .descriptors, for: .writing) == false)
    }

    @Test
    func isBlocked_withDescriptorUuidBlockedForWriting_isTrueForDescriptorsWriteOrAny() {
        #expect(sut.isBlocked(uuids.descriptors.blockedForWriting, in: .descriptors, for: .writing) == true)
        #expect(sut.isBlocked(uuids.descriptors.blockedForWriting, in: .descriptors, for: .any) == true)
    }

    @Test
    func isBlocked_withDescriptorUuidBlockedForWriting_isFalseForDescriptorsRead() {
        #expect(sut.isBlocked(uuids.descriptors.blockedForWriting, in: .descriptors, for: .reading) == false)
    }

    @Test(arguments: SecurityList.Operation.allCases)
    func isBlocked_withDescriptorUuidBlockedForAny_isAlwaysTrueForDescriptors(operation: SecurityList.Operation) {
        #expect(sut.isBlocked(uuids.descriptors.blockedForAny, in: .descriptors, for: operation) == true)
    }

    @Test(arguments: uuids.descriptors.all, SecurityList.Operation.allCases)
    func isBlocked_withAllDescriptorUuidsOnBlocklist_isFalseForServiceAndCharacteristicGroups(uuid: UUID, operation: SecurityList.Operation) {
        #expect(sut.isBlocked(uuid, in: .services, for: operation) == false)
        #expect(sut.isBlocked(uuid, in: .characteristics, for: operation) == false)
    }
}
