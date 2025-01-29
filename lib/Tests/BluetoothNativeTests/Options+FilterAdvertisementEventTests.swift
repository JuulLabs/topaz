import Bluetooth
import BluetoothClient
@testable import BluetoothNative
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
// swiftlint:disable:next type_body_length
struct Options_IncludeAdvertisementEventTests {

    /*
     Similar to Options+DecodeTests, examples from here:
     https://webbluetoothcg.github.io/web-bluetooth/#example-filter-by-services
     are being used to construct the test cases. Each numbered example has a list of
     nearby devices that will be tested against, and each sub-example will have a
     different Options configuration to test against that list. The list of nearby
     devices will be commented at the top of each example section.
     */

    /*
     Example 2 Nearby Devices

     Device    Advertised Services
     D1        A, B, C, D
     D2        A, B, E
     D3        C, D
     D4        E
     D5        <none>
     */

    let example2_advertisementEvents: [String: AdvertisementEvent]

    init() {
        let fakePeripheral_D1 = FakePeripheral(id: UUID(), name: "D1", services: [service_A, service_B, service_C, service_D])
        let fakePeripheral_D2 = FakePeripheral(id: UUID(), name: "D2", services: [service_A, service_B, service_E])
        let fakePeripheral_D3 = FakePeripheral(id: UUID(), name: "D3", services: [service_C, service_D])
        let fakePeripheral_D4 = FakePeripheral(id: UUID(), name: "D4", services: [service_E])
        let fakePeripheral_D5 = FakePeripheral(id: UUID(), name: "D5")

        example2_advertisementEvents = [
            "D1": AdvertisementEvent(fakePeripheral_D1, fakePeripheral_D1.fakeAd()),
            "D2": AdvertisementEvent(fakePeripheral_D2, fakePeripheral_D2.fakeAd()),
            "D3": AdvertisementEvent(fakePeripheral_D3, fakePeripheral_D3.fakeAd()),
            "D4": AdvertisementEvent(fakePeripheral_D4, fakePeripheral_D4.fakeAd()),
            "D5": AdvertisementEvent(fakePeripheral_D5, fakePeripheral_D5.fakeAd())
        ]
    }

//    private let example2_nearbyDeviceList = [AdvertisementEvent(, )]

    @Test
    func includeAdvertisementEventInDeviceList_example2_1_returnsCorrectAssessmentsOfAdvertisementEvents() {
        // { filters: [ {services: ["A", "B"]} ] }
        let sut = Options(filters: [Options.Filter(services: [service_A.uuid, service_B.uuid])])

        #expect(sut.includeAdvertisementEventInDeviceList(example2_advertisementEvents["D1"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(example2_advertisementEvents["D2"]!) == true)
        #expect(sut.includeAdvertisementEventInDeviceList(example2_advertisementEvents["D3"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(example2_advertisementEvents["D4"]!) == false)
        #expect(sut.includeAdvertisementEventInDeviceList(example2_advertisementEvents["D5"]!) == false)
    }
}
