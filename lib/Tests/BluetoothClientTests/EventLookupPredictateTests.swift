@testable import BluetoothClient
import Foundation
import TestHelpers
import Testing

@Suite("EventLookupPredictates")
struct EventLookupPredictateTests {

    @Test
    func predicate_emptyAttributesVsKeyWithoutAttributes_isTrue() {
        let key = EventRegistrationKey(name: .connect)
        let predicate = EventAttributes().predicate()
        #expect(predicate(key) == true)
    }

    @Test
    func predicate_emptyAttributesVsKeyWithPeripheral_isTrue() {
        let key = EventRegistrationKey(name: .connect, peripheralId: UUID(n: 0))
        let predicate = EventAttributes().predicate()
        #expect(predicate(key) == true)
    }

    @Test
    func predicate_emptyAttributesWithNameVsKeyWithSameName_isTrue() {
        let key = EventRegistrationKey(name: .connect)
        let predicate = EventAttributes().predicate(name: .connect)
        #expect(predicate(key) == true)
    }

    @Test
    func predicate_emptyAttributesWithNameVsKeyWithDifferentName_isFalse() {
        let key = EventRegistrationKey(name: .connect)
        let predicate = EventAttributes().predicate(name: .disconnect)
        #expect(predicate(key) == false)
    }

    @Test
    func predicate_attributesWithPeripheralVsKeyWithSamePeripheral_isTrue() {
        let key = EventRegistrationKey(name: .connect, peripheralId: UUID(n: 0))
        let predicate = EventAttributes(
            peripheralId: UUID(n: 0)
        ).predicate()
        #expect(predicate(key) == true)
    }

    @Test
    func predicate_attributesWithPeripheralVsKeyWithDifferentPeripheral_isFalse() {
        let key = EventRegistrationKey(name: .connect, peripheralId: UUID(n: 0))
        let predicate = EventAttributes(
            peripheralId: UUID(n: 1)
        ).predicate()
        #expect(predicate(key) == false)
    }

    @Test
    func predicate_attributesWithServiceVsKeyWithSameService_isTrue() {
        let key = EventRegistrationKey(name: .connect, serviceId: UUID(n: 0))
        let predicate = EventAttributes(
            serviceId: UUID(n: 0)
        ).predicate()
        #expect(predicate(key) == true)
    }

    @Test
    func predicate_attributesWithServiceVsKeyWithWithDifferentService_isFalse() {
        let key = EventRegistrationKey(name: .connect, serviceId: UUID(n: 0))
        let predicate = EventAttributes(
            serviceId: UUID(n: 1)
        ).predicate()
        #expect(predicate(key) == false)
    }

    @Test
    func predicate_attributesWithCharacteristicVsKeyWithSameCharacteristic_isTrue() {
        let key = EventRegistrationKey(name: .connect, characteristicId: UUID(n: 0))
        let predicate = EventAttributes(
            characteristicId: UUID(n: 0)
        ).predicate()
        #expect(predicate(key) == true)
    }

    @Test
    func predicate_attributesWithCharacteristicVsKeyWithWithDifferentCharacteristic_isFalse() {
        let key = EventRegistrationKey(name: .connect, characteristicId: UUID(n: 0))
        let predicate = EventAttributes(
            characteristicId: UUID(n: 1)
        ).predicate()
        #expect(predicate(key) == false)
    }

    @Test
    func predicate_attributesWithCharacteristicInstanceVsKeyWithSameCharacteristicInstance_isTrue() {
        let key = EventRegistrationKey(name: .connect, characteristicInstance: 0)
        let predicate = EventAttributes(
            characteristicInstance: 0
        ).predicate()
        #expect(predicate(key) == true)
    }

    @Test
    func predicate_attributesWithCharacteristicInstanceVsKeyWithWithDifferentCharacteristicInstance_isFalse() {
        let key = EventRegistrationKey(name: .connect, characteristicInstance: 0)
        let predicate = EventAttributes(
            characteristicInstance: 1
        ).predicate()
        #expect(predicate(key) == false)
    }

    @Test
    func predicate_attributesWithDescriptorVsKeyWithSameDescriptor_isTrue() {
        let key = EventRegistrationKey(name: .connect, descriptorId: UUID(n: 0))
        let predicate = EventAttributes(
            descriptorId: UUID(n: 0)
        ).predicate()
        #expect(predicate(key) == true)
    }

    @Test
    func predicate_attributesWithDescriptorVsKeyWithWithDifferentDescriptor_isFalse() {
        let key = EventRegistrationKey(name: .connect, descriptorId: UUID(n: 0))
        let predicate = EventAttributes(
            descriptorId: UUID(n: 1)
        ).predicate()
        #expect(predicate(key) == false)
    }
}
