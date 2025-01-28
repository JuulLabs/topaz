// swiftlint:disable file_length
import Bluetooth
@testable import BluetoothAction
import Foundation
import JsMessage
import Testing

extension Tag {
    @Tag static var options: Self
}

@Suite(.tags(.options))
// swiftlint:disable:next type_body_length
struct OptionsTests {

    // swiftlint:disable:next type_name
    private typealias sut = Options

    private let uuid_1 = UUID(uuidString: "0000fe18-0000-1000-8000-00805f9b34fb")!
    private let uuid_2 = UUID(uuidString: "00001001-0000-1000-8000-00805f9b34fb")!
    private let uuid_3 = UUID(uuidString: "0000fde4-0000-1000-8000-00805f9b34fb")!
    private let uuid_4 = UUID(uuidString: "00001000-0000-1000-8000-00805f9b34fb")!

    // A little unorthodox, but I'm using examples from here:
    // https://webbluetoothcg.github.io/web-bluetooth/#example-filter-by-services
    // to construct tests. It's too difficult to describe the input conditions in
    // the function name, so I've labled the function with the corresponding
    // exaple from the page above and commented its input dictionary.

    @Test
    func decode_example2_1_returnsCorrectOptionsObject() {
        // { filters: [ {services: ["A", "B"]} ] }
        let web_bluetooth_options = ["filters": JsType.bridge([["services": [uuid_1.uuidString, uuid_2.uuidString]]])]

        let result = try! sut.decode(from: web_bluetooth_options)

        let resultingFilters = result.filters
        expect(filters: resultingFilters, expectedCount: 1)

        expect(filterToTest: resultingFilters?[0], expectedServiceUuids: [uuid_1, uuid_2])
    }

    @Test
    func decode_example2_2_returnsCorrectOptionsObject() {
        // { filters: [ {services: [A, B]}, {services: [C, D]} ] }
        let web_bluetooth_options = ["filters": JsType.bridge([["services": [uuid_1.uuidString, uuid_2.uuidString]], ["services": [uuid_3.uuidString, uuid_4.uuidString]]])]

        let result = try! sut.decode(from: web_bluetooth_options)

        let resultingFilters = result.filters
        expect(filters: resultingFilters, expectedCount: 2)

        expect(filterToTest: resultingFilters?[0], expectedServiceUuids: [uuid_1, uuid_2])
        expect(filterToTest: resultingFilters?[1], expectedServiceUuids: [uuid_3, uuid_4])
    }

    @Test
    func decode_example2_3_returnsCorrectOptionsObject() {
        // { filters: [ {services: [A, B]} ], optionalServices: [E] }
        let web_bluetooth_options = ["filters": JsType.bridge([["services": [uuid_1.uuidString, uuid_2.uuidString]]]), "optionalServices": JsType.bridge([uuid_3.uuidString])]

        let result = try! sut.decode(from: web_bluetooth_options)

        let resultingFilters = result.filters
        expect(filters: resultingFilters, expectedCount: 1)

        expect(filterToTest: resultingFilters?[0], expectedServiceUuids: [uuid_1, uuid_2])

        #expect(result.optionalServices == [uuid_3])
    }

    @Test
    func decode_example3_1_returnsCorrectOptionsObject() {
        // { filters: [ {name: "Unique Name"} ] }
        let web_bluetooth_options = ["filters": JsType.bridge([["name": "Batman's Shark Repellant"]])]

        let result = try! sut.decode(from: web_bluetooth_options)

        let resultingFilters = result.filters
        expect(filters: resultingFilters, expectedCount: 1)
        let nameFilter = resultingFilters?.first
        #expect(nameFilter?.name == "Batman's Shark Repellant")
    }

    @Test
    func decode_example3_2_returnsCorrectOptionsObject() {
        // { filters: [ {namePrefix: "Device"} ] }
        let web_bluetooth_options = ["filters": JsType.bridge([["namePrefix": "Batman's"]])]

        let result = try! sut.decode(from: web_bluetooth_options)

        let resultingFilters = result.filters
        expect(filters: resultingFilters, expectedCount: 1)
        let namePrefixFilter = resultingFilters?.first
        #expect(namePrefixFilter?.namePrefix == "Batman's")
    }

    @Test
    func decode_example3_3_returnsCorrectOptionsObject() {
        // { filters: [ {name: "First De"}, {name: "First Device"} ] }
        let web_bluetooth_options = ["filters": JsType.bridge([["name": "Bat"], ["name": "Batman"]])]

        let result = try! sut.decode(from: web_bluetooth_options)

        let resultingFilters = result.filters
        expect(filters: resultingFilters, expectedCount: 2)

        let nameFilter_1 = resultingFilters?[0]
        #expect(nameFilter_1?.name == "Bat")

        let nameFilter_2 = resultingFilters?[1]
        #expect(nameFilter_2?.name == "Batman")
    }

    @Test
    func decode_example3_4_returnsCorrectOptionsObject() {
        // { filters: [ {namePrefix: "First"}, {name: "Unique Name"} ] }
        let web_bluetooth_options = ["filters": JsType.bridge([["namePrefix": "Bat"], ["name": "Robin"]])]

        let result = try! sut.decode(from: web_bluetooth_options)

        let resultingFilters = result.filters
        expect(filters: resultingFilters, expectedCount: 2)

        let namePrefixFilter = resultingFilters?.first { $0.namePrefix != nil }
        #expect(namePrefixFilter?.namePrefix == "Bat")

        let nameFilter = resultingFilters?.first { $0.name != nil }
        #expect(nameFilter?.name == "Robin")
    }

    @Test
    func decode_example3_5_returnsCorrectOptionsObject() {
        // { filters: [ {services: [C], namePrefix: "Device"}, {name: "Unique Name"} ] }
        let web_bluetooth_options = ["filters": JsType.bridge([["services": [uuid_1.uuidString], "namePrefix": "Bat"], ["name": "Batman"]])]

        let result = try! sut.decode(from: web_bluetooth_options)

        let resultingFilters = result.filters
        expect(filters: resultingFilters, expectedCount: 2)

        let serviceAndNamePrefixFilter = resultingFilters?.first { $0.services != nil }
        expect(filterToTest: serviceAndNamePrefixFilter, expectedServiceUuids: [uuid_1], namePrefix: "Bat")

        let nameFilter = resultingFilters?.first { $0.name != nil }
        expect(filterToTest: nameFilter, name: "Batman")
    }

    @Test
    func decode_example3_6_returnsCorrectOptionsObject() {
        // { filters: [{namePrefix: "Device"}], exclusionFilters: [{name: "Device Third"}] }
        let web_bluetooth_options = ["filters": JsType.bridge([["namePrefix": "Bat"]]), "exclusionFilters": JsType.bridge([["name": "Batman"]])]

        let result = try! sut.decode(from: web_bluetooth_options)

        let resultingFilters = result.filters
        expect(filters: resultingFilters, expectedCount: 1)
        expect(filterToTest: resultingFilters?.first, namePrefix: "Bat")

        let exclusionFilters = result.exclusionFilters
        expect(filters: exclusionFilters, expectedCount: 1)
        expect(filterToTest: exclusionFilters?.first, name: "Batman")
    }

    @Test
    func decode_example3_7_returnsCorrectOptionsObject() {
        // { filters: [{namePrefix: "Device"}], exclusionFilters: [{namePrefix: "Device F"}] }
        let web_bluetooth_options = ["filters": JsType.bridge([["namePrefix": "Bat"]]), "exclusionFilters": JsType.bridge([["namePrefix": "Rob"]])]

        let result = try! sut.decode(from: web_bluetooth_options)

        let resultingFilters = result.filters
        expect(filters: resultingFilters, expectedCount: 1)
        expect(filterToTest: resultingFilters?.first, namePrefix: "Bat")

        let exclusionFilters = result.exclusionFilters
        expect(filters: exclusionFilters, expectedCount: 1)
        expect(filterToTest: exclusionFilters?.first, namePrefix: "Rob")
    }

    @Test
    func decode_example3_8_returnsCorrectOptionsObject() {
        // { filters: [{services: [C]}, {namePrefix: "Device"}], exclusionFilters: [{services: [A]}, {name: "Device Fourth"}] }
        let web_bluetooth_options = ["filters": JsType.bridge([["services": [uuid_3.uuidString]], ["namePrefix": "Bat"]]), "exclusionFilters": JsType.bridge([["services": [uuid_1.uuidString]], ["name": "Robin"]])]

        let result = try! sut.decode(from: web_bluetooth_options)

        let resultingFilters = result.filters
        expect(filters: resultingFilters, expectedCount: 2)

        expect(filterToTest: resultingFilters?.first { $0.services != nil }, expectedServiceUuids: [uuid_3])
        expect(filterToTest: resultingFilters?.first { $0.namePrefix != nil }, namePrefix: "Bat")

        let exclusionFilters = result.exclusionFilters
        expect(filters: exclusionFilters, expectedCount: 2)

        expect(filterToTest: exclusionFilters?.first { $0.services != nil }, expectedServiceUuids: [uuid_1])
        expect(filterToTest: exclusionFilters?.first { $0.name != nil }, name: "Robin")
    }

    @Test
    func decode_example4_1_returnsCorrectOptionsObject() {
        // { filters: [{ manufacturerData: [{ companyIdentifier: 17 }] }] }
        let web_bluetooth_options = ["filters": JsType.bridge([["manufacturerData": [["companyIdentifier": 7351]]]])]

        let result = try! sut.decode(from: web_bluetooth_options)

        let resultingFilters = result.filters
        expect(filters: resultingFilters, expectedCount: 1)

        let manufacturerDataFilters = resultingFilters?.first?.manufacturerData
        #expect(manufacturerDataFilters?.count == 1)
        let manufacturerDataFilter = manufacturerDataFilters?.first
        #expect(manufacturerDataFilter?.companyIdentifier == 7351)
    }

    @Test
    func decode_example4_2_returnsCorrectOptionsObject() {
        // { filters: [{ serviceData: [{ service: "A" }] }] }
        let web_bluetooth_options = ["filters": JsType.bridge([["serviceData": [["service": uuid_1.uuidString]]]])]

        let result = try! sut.decode(from: web_bluetooth_options)

        let resultingFilters = result.filters
        expect(filters: resultingFilters, expectedCount: 1)

        let serviceDataFilters = resultingFilters?.first?.serviceData
        #expect(serviceDataFilters?.count == 1)
        let serviceDataFilter = serviceDataFilters?.first
        #expect(serviceDataFilter?.service == uuid_1)
    }

    @Test
    func decode_example4_3_returnsCorrectOptionsObject() {
        // { filters: [ { manufacturerData: [{ companyIdentifier: 17 }] }, { serviceData: [{ service: "A" }] } ] }
        let web_bluetooth_options = ["filters": JsType.bridge([["manufacturerData": [["companyIdentifier": 7351]]], ["serviceData": [["service": uuid_1.uuidString]]]])]

        let result = try! sut.decode(from: web_bluetooth_options)

        let resultingFilters = result.filters
        expect(filters: resultingFilters, expectedCount: 2)

        let manufacturerDataFilters = resultingFilters?.first { $0.manufacturerData != nil }?.manufacturerData
        #expect(manufacturerDataFilters?.count == 1)
        let manufacturerDataFilter = manufacturerDataFilters?.first
        #expect(manufacturerDataFilter?.companyIdentifier == 7351)

        let serviceDataFilters = resultingFilters?.first { $0.serviceData != nil }?.serviceData
        #expect(serviceDataFilters?.count == 1)
        let serviceDataFilter = serviceDataFilters?.first
        #expect(serviceDataFilter?.service == uuid_1)
    }

    @Test
    func decode_example4_4_returnsCorrectOptionsObject() {
        // { filters: [{ manufacturerData: [{ companyIdentifier: 17 }], serviceData: [{ service: "A" }] } ] }
        let web_bluetooth_options = ["filters": JsType.bridge([["manufacturerData": [["companyIdentifier": 7351]], "serviceData": [["service": uuid_1.uuidString]]]])]

        let result = try! sut.decode(from: web_bluetooth_options)

        let resultingFilters = result.filters
        expect(filters: resultingFilters, expectedCount: 1)

        let filter = resultingFilters?.first

        let manufacturerFilter = filter?.manufacturerData
        #expect(manufacturerFilter?.count == 1)
        let manufacturerDataFilter = manufacturerFilter?.first
        #expect(manufacturerDataFilter?.companyIdentifier == 7351)

        let serviceFilter = filter?.serviceData
        #expect(serviceFilter?.count == 1)
        let serviceDataFilter = serviceFilter?.first
        #expect(serviceDataFilter?.service == uuid_1)
    }

    @Test
    func decode_example4_5_returnsCorrectOptionsObject() {
        // { filters: [{ manufacturerData: [{ companyIdentifier: 17, dataPrefix: Uint8Array([1, 2, 3]) }]}] }
        let web_bluetooth_options = ["filters": JsType.bridge([["manufacturerData": [["companyIdentifier": 7351, "dataPrefix": [1, 2, 3]]]]])]

        let result = try! sut.decode(from: web_bluetooth_options)

        let resultingFilters = result.filters
        expect(filters: resultingFilters, expectedCount: 1)

        let manufacturerFilter = resultingFilters?.first?.manufacturerData
        #expect(manufacturerFilter?.count == 1)
        let manufacturerDataFilter = manufacturerFilter?.first
        #expect(manufacturerDataFilter?.companyIdentifier == 7351)
        #expect(manufacturerDataFilter?.dataPrefix == [1, 2, 3])
    }

    @Test
    func decode_example4_6_returnsCorrectOptionsObject() {
        // { filters: [{ manufacturerData: [{ companyIdentifier: 17, dataPrefix: Uint8Array([1, 2, 3, 4]) }]}] }
        let web_bluetooth_options = ["filters": JsType.bridge([["manufacturerData": [["companyIdentifier": 7351, "dataPrefix": [1, 2, 3, 4]]]]])]

        let result = try! sut.decode(from: web_bluetooth_options)

        let resultingFilters = result.filters
        expect(filters: resultingFilters, expectedCount: 1)

        let manufacturerFilter = resultingFilters?.first?.manufacturerData
        #expect(manufacturerFilter?.count == 1)
        let manufacturerDataFilter = manufacturerFilter?.first
        #expect(manufacturerDataFilter?.companyIdentifier == 7351)
        #expect(manufacturerDataFilter?.dataPrefix == [1, 2, 3, 4])
    }

    @Test
    func decode_example4_7_returnsCorrectOptionsObject() {
        // { filters: [{ manufacturerData: [{ companyIdentifier: 17, dataPrefix: Uint8Array([1]) }]}] }
        let web_bluetooth_options = ["filters": JsType.bridge([["manufacturerData": [["companyIdentifier": 7351, "dataPrefix": [1]]]]])]

        let result = try! sut.decode(from: web_bluetooth_options)

        let resultingFilters = result.filters
        expect(filters: resultingFilters, expectedCount: 1)

        let manufacturerFilter = resultingFilters?.first?.manufacturerData
        #expect(manufacturerFilter?.count == 1)
        let manufacturerDataFilter = manufacturerFilter?.first
        #expect(manufacturerDataFilter?.companyIdentifier == 7351)
        #expect(manufacturerDataFilter?.dataPrefix == [1])
    }

    @Test
    func decode_example4_8_returnsCorrectOptionsObject() {
        // { filters: [{ manufacturerData: [{ companyIdentifier: 17, dataPrefix: Uint8Array([0x91, 0xAA]), mask: Uint8Array([0x0f, 0x57])}]}] }
        let web_bluetooth_options = ["filters": JsType.bridge([["manufacturerData": [["companyIdentifier": 7351, "dataPrefix": [0x91, 0xAA], "mask": [0x0f, 0x57]]]]])]

        let result = try! sut.decode(from: web_bluetooth_options)

        let resultingFilters = result.filters
        expect(filters: resultingFilters, expectedCount: 1)

        let manufacturerFilter = resultingFilters?.first?.manufacturerData
        #expect(manufacturerFilter?.count == 1)
        let manufacturerDataFilter = manufacturerFilter?.first
        #expect(manufacturerDataFilter?.companyIdentifier == 7351)
        #expect(manufacturerDataFilter?.dataPrefix == [0x91, 0xAA])
        #expect(manufacturerDataFilter?.mask == [0x0f, 0x57])
    }

    @Test
    func decode_example4_9_returnsCorrectOptionsObject() {
        // { filters: [{ manufacturerData: [{ companyIdentifier: 17 }, { companyIdentifier: 18 }]}] }
        let web_bluetooth_options = ["filters": JsType.bridge([["manufacturerData": [["companyIdentifier": 17], ["companyIdentifier": 18]]]])]

        let result = try! sut.decode(from: web_bluetooth_options)

        let resultingFilters = result.filters
        expect(filters: resultingFilters, expectedCount: 1)

        let manufacturerFilter = resultingFilters?.first?.manufacturerData
        #expect(manufacturerFilter?.count == 2)
        #expect(manufacturerFilter?[0].companyIdentifier == 17)
        #expect(manufacturerFilter?[1].companyIdentifier == 18)
    }

    @Test
    func decode_example5_1_throwsInvalidInputError() {
        // {}
        let web_bluetooth_options: [String: JsType] = [:]

        #expect(throws: OptionsError.invalidInput) {
            try sut.decode(from: web_bluetooth_options)
        }
    }

    @Test
    func decode_example5_2_throwsInvalidInputError() {
        // { filters: [] }
        let web_bluetooth_options = ["filters": JsType.bridge([])]

        #expect(throws: OptionsError.invalidInput) {
            try sut.decode(from: web_bluetooth_options)
        }
    }

    @Test
    func decode_example5_3_throwsInvalidInputError() {
        // { filters: [ {} ] }
        let web_bluetooth_options = ["filters": JsType.bridge([[:]])]

        #expect(throws: OptionsError.invalidInput) {
            try sut.decode(from: web_bluetooth_options)
        }
    }

    // Note: Example 5-4 is covered by another test

    @Test
    func decode_example5_5_throwsInvalidInputError() {
        // { filters: [...], acceptAllDevices:true }
        let web_bluetooth_options = ["filters": JsType.bridge([["services": [uuid_1.uuidString]]]), "acceptAllDevices": JsType.bridge(true)]

        #expect(throws: OptionsError.invalidInput) {
            try sut.decode(from: web_bluetooth_options)
        }
    }

    @Test
    func decode_example5_6_throwsInvalidInputError() {
        // { exclusionFilters: [...], acceptAllDevices:true }
        let web_bluetooth_options = ["exclusionFilters": JsType.bridge([["services": [uuid_1.uuidString]]]), "acceptAllDevices": JsType.bridge(true)]

        #expect(throws: OptionsError.invalidInput) {
            try sut.decode(from: web_bluetooth_options)
        }
    }

    @Test
    func decode_example5_7_throwsInvalidInputError() {
        // { exclusionFilters: [...] }
        let web_bluetooth_options = ["exclusionFilters": JsType.bridge([["services": [uuid_1.uuidString]]])]

        #expect(throws: OptionsError.invalidInput) {
            try sut.decode(from: web_bluetooth_options)
        }
    }

    @Test
    func decode_example5_8_throwsInvalidInputError() {
        // { filters: [...], exclusionFilters: [] }
        let web_bluetooth_options = ["filters": JsType.bridge([["services": [uuid_1.uuidString]]]), "exclusionFilters": JsType.bridge([])]

        #expect(throws: OptionsError.invalidInput) {
            try sut.decode(from: web_bluetooth_options)
        }
    }

    @Test
    func decode_example5_9_throwsInvalidInputError() {
        // { filters: [{namePrefix: ""}] }
        let web_bluetooth_options = ["filters": JsType.bridge([["namePrefix": ""]])]

        #expect(throws: OptionsError.invalidInput) {
            try sut.decode(from: web_bluetooth_options)
        }
    }

    // Note: I've altered this example slightly because, by virtue of providing an empty list of filters, this test passed
    // without me coding for what it should be testing--that manufacturerData, if provided, is not empty.
    @Test
    func decode_example5_10_throwsInvalidInputError() {
        // { filters: [{manufacturerData: []}] }
        let web_bluetooth_options = ["filters": JsType.bridge([["services": [uuid_1.uuidString]], ["manufacturerData": []]])]

        #expect(throws: OptionsError.invalidInput) {
            try sut.decode(from: web_bluetooth_options)
        }
    }

    // Note: I've altered this example slightly because, by virtue of providing an empty list of filters, this test passed
    // without me coding for what it should be testing--that serviceData, if provided, is not empty.
    @Test
    func decode_example5_11_throwsInvalidInputError() {
        // { filters: [{serviceData: []}] }
        let web_bluetooth_options = ["filters": JsType.bridge([["services": [uuid_1.uuidString]], ["serviceData": []]])]

        #expect(throws: OptionsError.invalidInput) {
            try sut.decode(from: web_bluetooth_options)
        }
    }

    // Note: The next few tests do not have correpsonding examples, but these needed to be
    // written to ensure coverage.

    @Test
    func decode_fullServiceDataFilter_returnsCorrectOptionsObject() {
        // { filters: [{ serviceData: [{ service: "A", dataPrefix: Uint8Array([0x91, 0xAA]), mask: Uint8Array([0x0f, 0x57]) }] }] }
        let web_bluetooth_options = ["filters": JsType.bridge([["serviceData": [["service": uuid_1.uuidString, "dataPrefix": [0x91, 0xAA], "mask": [0x0f, 0x57]]]]])]

        let result = try! sut.decode(from: web_bluetooth_options)

        let resultingFilters = result.filters
        expect(filters: resultingFilters, expectedCount: 1)

        let serviceFilter = resultingFilters?.first?.serviceData
        #expect(serviceFilter?.count == 1)
        let serviceDataFilter = serviceFilter?.first
        #expect(serviceDataFilter?.service == uuid_1)
        #expect(serviceDataFilter?.dataPrefix == [0x91, 0xAA])
        #expect(serviceDataFilter?.mask == [0x0f, 0x57])
    }

    @Test
    func decode_optionalManufacturerData_returnsCorrectOptionsObject() {
        // { optionalManufacturerData: [1, 2, 3, 4] }
        let web_bluetooth_options = ["optionalManufacturerData": JsType.bridge([1, 2, 3, 4])]

        let result = try! sut.decode(from: web_bluetooth_options)

        #expect(result.optionalManufacturerData == [1, 2, 3, 4])
    }

    @Test
    func decode_acceptAllDevicesTrue_returnsCorrectOptionsObject() {
        // { acceptAllDevices: true }
        let web_bluetooth_options = ["acceptAllDevices": JsType.bridge(true)]

        let result = try! sut.decode(from: web_bluetooth_options)

        #expect(result.acceptAllDevices == true)
    }

    @Test
    func decode_acceptAllDevicesFalse_returnsCorrectOptionsObject() {
        // { acceptAllDevices: false }
        let web_bluetooth_options = ["acceptAllDevices": JsType.bridge(false)]

        let result = try! sut.decode(from: web_bluetooth_options)

        #expect(result.acceptAllDevices == false)
    }

    private func expect(filters: [Options.Filter]?, expectedCount: Int) {
        #expect(filters != nil)
        #expect(filters?.count == expectedCount)
    }

    private func expect(filterToTest: Options.Filter?, expectedServiceUuids: [UUID]? = nil, namePrefix: String? = nil, name: String? = nil) {

        if let expectedServiceUuids = expectedServiceUuids {
            #expect(filterToTest?.services != nil)
            let services = filterToTest?.services
            #expect(services?.count == expectedServiceUuids.count)
            for i in 0..<expectedServiceUuids.count {
                #expect(services?[i] == expectedServiceUuids[i])
            }
        }

        if let namePrefix = namePrefix {
            #expect(filterToTest?.namePrefix == namePrefix)
        }

        if let name = name {
            #expect(filterToTest?.name == name)
        }
    }
}
