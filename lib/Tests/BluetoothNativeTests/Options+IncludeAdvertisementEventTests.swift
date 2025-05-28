import Bluetooth
import BluetoothClient
@testable import BluetoothNative
import EventBus
import Foundation
import Testing

extension Tag {
    @Tag static var options: Self
}

private let service_A = FakeService(uuid: UUID(uuidString: "0000fe18-0000-1000-8000-00805f9b34fb")!)
private let service_B = FakeService(uuid: UUID(uuidString: "00001001-0000-1000-8000-00805f9b34fb")!)
private let service_C = FakeService(uuid: UUID(uuidString: "0000fde4-0000-1000-8000-00805f9b34fb")!)
private let service_D = FakeService(uuid: UUID(uuidString: "00001000-0000-1000-8000-00805f9b34fb")!)
private let service_E = FakeService(uuid: UUID(uuidString: "65ae0bb2-6699-458d-8770-21d3a1f1db6e")!)

@Suite(.tags(.options))
// swiftlint:disable:next type_name
struct Options_IncludeAdvertisementEventTests {

    /*
     Similar to Options+DecodeTests, examples from here:
     https://webbluetoothcg.github.io/web-bluetooth/#example-filter-by-services
     are being used to construct the test cases. All numbered examples will use this list of
     nearby devices, and each sub-example will have a different Options configuration
     to test against it.
     */

    /*
     Nearby Devices

     Device    Advertised Services  Advertised Device Name  ManufacturerData    ServiceData
     D1        A, B, C, D           First De…               17: 01 02 03
     D2        A, B, E              <none>                                      A: 01 02 03
     D3        C, D                 Device Third
     D4        E                    Device Fourth
     D5        <none>               Unique Name
     */
    let advertisementEvents: [String: AdvertisementEvent]

    init() {
        let fakePeripheral_D1 = FakePeripheral(id: UUID(), name: "D1")
        let fakePeripheral_D2 = FakePeripheral(id: UUID(), name: "D2")
        let fakePeripheral_D3 = FakePeripheral(id: UUID(), name: "D3")
        let fakePeripheral_D4 = FakePeripheral(id: UUID(), name: "D4")
        let fakePeripheral_D5 = FakePeripheral(id: UUID(), name: "D5")

        advertisementEvents = [
            "D1": AdvertisementEvent(fakePeripheral_D1, fakePeripheral_D1.fakeAdvertisement(localName: "First De...", manufacturerData: ManufacturerData(code: 17, data: Data([01, 02, 03])), serviceUUIDs: [service_A.uuid, service_B.uuid, service_C.uuid, service_D.uuid])),
            "D2": AdvertisementEvent(fakePeripheral_D2, fakePeripheral_D2.fakeAdvertisement(localName: nil, serviceData: ServiceData([service_A.uuid: Data([01, 02, 03])]), serviceUUIDs: [service_A.uuid, service_B.uuid, service_E.uuid])),
            "D3": AdvertisementEvent(fakePeripheral_D3, fakePeripheral_D3.fakeAdvertisement(localName: "Device Third", serviceUUIDs: [service_C.uuid, service_D.uuid])),
            "D4": AdvertisementEvent(fakePeripheral_D4, fakePeripheral_D4.fakeAdvertisement(localName: "Device Fourth", serviceUUIDs: [service_E.uuid])),
            "D5": AdvertisementEvent(fakePeripheral_D5, fakePeripheral_D5.fakeAdvertisement(localName: "Unique Name")),
        ]
    }

    @Test
    func includeAdvertisementEventInDeviceList_example2_1_returnsCorrectAssessmentsOfAdvertisementEvents() {
        // { filters: [ {services: ["A", "B"]} ] }
        let sut = Options(filters: [Options.Filter(services: [service_A.uuid, service_B.uuid])])

        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D1"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D2"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D3"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D4"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D5"]!) == false)
    }

    @Test
    func includeAdvertisementEventInDeviceList_example2_2_returnsCorrectAssessmentsOfAdvertisementEvents() {
        // { filters: [ {services: [A, B]}, {services: [C, D]} ] }
        let sut = Options(filters: [Options.Filter(services: [service_A.uuid, service_B.uuid]), Options.Filter(services: [service_C.uuid, service_D.uuid])])

        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D1"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D2"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D3"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D4"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D5"]!) == false)
    }

    @Test
    func includeAdvertisementEventInDeviceList_example2_3_returnsCorrectAssessmentsOfAdvertisementEvents() {
        // { filters: [ {services: [A, B]} ], optionalServices: [E] }
        let sut = Options(filters: [Options.Filter(services: [service_A.uuid, service_B.uuid])], optionalServices: [service_E.uuid])

        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D1"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D2"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D3"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D4"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D5"]!) == false)
    }

    @Test
    func includeAdvertisementEventInDeviceList_example3_1_returnsCorrectAssessmentsOfAdvertisementEvents() {
        // { filters: [ {name: "Unique Name"} ] }
        let sut = Options(filters: [Options.Filter(name: "Unique Name")])

        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D1"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D2"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D3"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D4"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D5"]!) == true)
    }

    @Test
    func includeAdvertisementEventInDeviceList_example3_2_returnsCorrectAssessmentsOfAdvertisementEvents() {
        // { filters: [ {namePrefix: "Device"} ] }
        let sut = Options(filters: [Options.Filter(namePrefix: "Device")])

        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D1"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D2"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D3"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D4"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D5"]!) == false)
    }

    @Test
    func includeAdvertisementEventInDeviceList_example3_3_returnsCorrectAssessmentsOfAdvertisementEvents() {
        // { filters: [ {name: "First De"}, {name: "First Device"} ] }
        let sut = Options(filters: [Options.Filter(name: "First De"), Options.Filter(name: "First Device")])

        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D1"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D2"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D3"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D4"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D5"]!) == false)
    }

    @Test
    func includeAdvertisementEventInDeviceList_example3_4_returnsCorrectAssessmentsOfAdvertisementEvents() {
        // { filters: [ {namePrefix: "First"}, {name: "Unique Name"} ] }
        let sut = Options(filters: [Options.Filter(namePrefix: "First"), Options.Filter(name: "Unique Name")])

        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D1"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D2"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D3"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D4"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D5"]!) == true)
    }

    @Test
    func includeAdvertisementEventInDeviceList_example3_5_returnsCorrectAssessmentsOfAdvertisementEvents() {
        // { filters: [ {services: [C], namePrefix: "Device"}, {name: "Unique Name"} ] }
        let sut = Options(filters: [Options.Filter(services: [service_C.uuid], namePrefix: "Device"), Options.Filter(name: "Unique Name")])

        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D1"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D2"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D3"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D4"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D5"]!) == true)
    }

    @Test
    func includeAdvertisementEventInDeviceList_example3_6_returnsCorrectAssessmentsOfAdvertisementEvents() {
        // { filters: [{namePrefix: "Device"}], exclusionFilters: [{name: "Device Third"}] }
        let sut = Options(filters: [Options.Filter(namePrefix: "Device")], exclusionFilters: [Options.Filter(name: "Device Third")])

        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D1"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D2"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D3"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D4"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D5"]!) == false)
    }

    @Test
    func includeAdvertisementEventInDeviceList_example3_7_returnsCorrectAssessmentsOfAdvertisementEvents() {
        // { filters: [{namePrefix: "Device"}], exclusionFilters: [{namePrefix: "Device F"}] }
        let sut = Options(filters: [Options.Filter(namePrefix: "Device")], exclusionFilters: [Options.Filter(namePrefix: "Device F")])

        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D1"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D2"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D3"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D4"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D5"]!) == false)
    }

    @Test
    func includeAdvertisementEventInDeviceList_example3_8_returnsCorrectAssessmentsOfAdvertisementEvents() {
        // { filters: [{services: [C]}, {namePrefix: "Device"}], exclusionFilters: [{services: [A]}, {name: "Device Fourth"}] }
        let sut = Options(filters: [Options.Filter(services: [service_C.uuid]), Options.Filter(namePrefix: "Device")], exclusionFilters: [Options.Filter(services: [service_A.uuid]), Options.Filter(name: "Device Fourth")])

        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D1"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D2"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D3"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D4"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D5"]!) == false)
    }

    @Test
    func includeAdvertisementEventInDeviceList_example4_1_returnsCorrectAssessmentsOfAdvertisementEvents() {
        // { filters: [{ manufacturerData: [{ companyIdentifier: 17 }] }] }
        let sut = Options(filters: [Options.Filter(manufacturerData: [Options.Filter.ManufacturerData(companyIdentifier: 17)])])

        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D1"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D2"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D3"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D4"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D5"]!) == false)
    }

    @Test
    func includeAdvertisementEventInDeviceList_example4_2_returnsCorrectAssessmentsOfAdvertisementEvents() {
        // { filters: [{ serviceData: [{ service: "A" }] }] }
        let sut = Options(filters: [Options.Filter(serviceData: [Options.Filter.ServiceData(service: service_A.uuid)])])

        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D1"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D2"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D3"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D4"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D5"]!) == false)
    }

    @Test
    func includeAdvertisementEventInDeviceList_example4_3_returnsCorrectAssessmentsOfAdvertisementEvents() {
        // { filters: [ { manufacturerData: [{ companyIdentifier: 17 }] }, { serviceData: [{ service: "A" }] } ] }
        let sut = Options(filters: [Options.Filter(manufacturerData: [Options.Filter.ManufacturerData(companyIdentifier: 17)]), Options.Filter(serviceData: [Options.Filter.ServiceData(service: service_A.uuid)])])

        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D1"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D2"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D3"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D4"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D5"]!) == false)
    }

    @Test
    func includeAdvertisementEventInDeviceList_example4_4_returnsCorrectAssessmentsOfAdvertisementEvents() {
        // { filters: [{ manufacturerData: [{ companyIdentifier: 17 }], serviceData: [{ service: "A" }] } ] }
        let sut = Options(filters: [Options.Filter(manufacturerData: [Options.Filter.ManufacturerData(companyIdentifier: 17)], serviceData: [Options.Filter.ServiceData(service: service_A.uuid)])])

        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D1"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D2"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D3"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D4"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D5"]!) == false)
    }

    @Test
    func includeAdvertisementEventInDeviceList_example4_5_returnsCorrectAssessmentsOfAdvertisementEvents() {
        // { filters: [{ manufacturerData: [{ companyIdentifier: 17, dataPrefix: Uint8Array([1, 2, 3]) }]}] }
        let sut = Options(filters: [Options.Filter(manufacturerData: [Options.Filter.ManufacturerData(companyIdentifier: 17, dataPrefix: [1, 2, 3])])])

        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D1"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D2"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D3"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D4"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D5"]!) == false)
    }

    @Test
    func includeAdvertisementEventInDeviceList_example4_6_returnsCorrectAssessmentsOfAdvertisementEvents() {
        // { filters: [{ manufacturerData: [{ companyIdentifier: 17, dataPrefix: Uint8Array([1, 2, 3, 4]) }]}] }
        let sut = Options(filters: [Options.Filter(manufacturerData: [Options.Filter.ManufacturerData(companyIdentifier: 17, dataPrefix: [1, 2, 3, 4])])])

        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D1"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D2"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D3"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D4"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D5"]!) == false)
    }

    @Test
    func includeAdvertisementEventInDeviceList_example4_7_returnsCorrectAssessmentsOfAdvertisementEvents() {
        // { filters: [{ manufacturerData: [{ companyIdentifier: 17, dataPrefix: Uint8Array([1]) }]}] }
        let sut = Options(filters: [Options.Filter(manufacturerData: [Options.Filter.ManufacturerData(companyIdentifier: 17, dataPrefix: [1])])])

        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D1"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D2"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D3"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D4"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D5"]!) == false)
    }

    @Test
    func includeAdvertisementEventInDeviceList_example4_8_returnsCorrectAssessmentsOfAdvertisementEvents() {
        // { filters: [{ manufacturerData: [{ companyIdentifier: 17, dataPrefix: Uint8Array([0x91, 0xAA]), mask: Uint8Array([0x0f, 0x57])}]}] }
        let sut = Options(filters: [Options.Filter(manufacturerData: [Options.Filter.ManufacturerData(companyIdentifier: 17, dataPrefix: [0x91, 0xAA], mask: [0x0f, 0x57])])])

        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D1"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D2"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D3"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D4"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D5"]!) == false)
    }

    @Test
    func includeAdvertisementEventInDeviceList_example4_9_returnsCorrectAssessmentsOfAdvertisementEvents() {
        // { filters: [{ manufacturerData: [{ companyIdentifier: 17 }, { companyIdentifier: 18 }]}] }
        let sut = Options(filters: [Options.Filter(manufacturerData: [Options.Filter.ManufacturerData(companyIdentifier: 17), Options.Filter.ManufacturerData(companyIdentifier: 18)])])

        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D1"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D2"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D3"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D4"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D5"]!) == false)
    }

    /*
     The following tests are not based on the Web spec, but are provided for full coverage.
     Example 5 is skipped because this function should never be called if the web passed an
     invalid options configuration.
     */

    @Test
    func includeAdvertisementEventInDeviceList_serviceDataFilterWithMatchingDataPrefix_trueForD2() {
        let sut = Options(filters: [Options.Filter(serviceData: [Options.Filter.ServiceData(service: service_A.uuid, dataPrefix: [1, 2])])])

        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D1"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D2"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D3"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D4"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D5"]!) == false)
    }

    @Test
    func includeAdvertisementEventInDeviceList_serviceDataFilterWithUnmatchingDataPrefix_allFalse() {
        let sut = Options(filters: [Options.Filter(serviceData: [Options.Filter.ServiceData(service: service_A.uuid, dataPrefix: [1, 3])])])

        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D1"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D2"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D3"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D4"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D5"]!) == false)
    }

    @Test
    func includeAdvertisementEventInDeviceList_serviceDataFilterWithTooLongDataPrefix_allFalse() {
        let sut = Options(filters: [Options.Filter(serviceData: [Options.Filter.ServiceData(service: service_A.uuid, dataPrefix: [1, 2, 3, 4])])])

        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D1"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D2"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D3"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D4"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D5"]!) == false)
    }

    @Test
    func includeAdvertisementEventInDeviceList_serviceDataFilterWithDifferentAdDataButMaskAllowsIt_trueForD2() {
        let sut = Options(filters: [Options.Filter(serviceData: [Options.Filter.ServiceData(service: service_A.uuid, dataPrefix: [5, 6], mask: [1, 3])])])

        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D1"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D2"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D3"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D4"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D5"]!) == false)
    }

    @Test
    func includeAdvertisementEventInDeviceList_acceptAllDevicesTrue_allTrue() {
        let sut = Options(acceptAllDevices: true)

        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D1"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D2"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D3"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D4"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(advertisementEvents["D5"]!) == true)
    }
}
