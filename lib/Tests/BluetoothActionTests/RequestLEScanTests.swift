import Bluetooth
@testable import BluetoothAction
import BluetoothClient
import BluetoothMessage
import Foundation
import JsMessage
import Testing

extension Tag {
    @Tag static var requestLEScan: Self
}

@Suite(.tags(.requestLEScan))
struct RequestLEScanRequestTests {

    @Test
    func decode_withNil_isStartRequestWithDefaults() throws {
        let options = try #require(decodeStartRequest(nil))
        #expect(options.acceptAllAdvertisements == false)
        #expect(options.keepRepeatedDevices == false)
    }

    @Test
    func decode_withEmptyObject_isStartRequestWithDefaults() throws {
        let options = try #require(decodeStartRequest([:]))
        #expect(options.acceptAllAdvertisements == false)
        #expect(options.keepRepeatedDevices == false)
    }

    @Test
    func decode_withEmptyOptions_isStartRequestWithDefaults() throws {
        let options = try #require(decodeStartRequest(["options": .dictionary([:])]))
        #expect(options.acceptAllAdvertisements == false)
        #expect(options.keepRepeatedDevices == false)
    }

    @Test
    func decode_optionsWithAcceptAllAdvertisementsTrue_succeeds() throws {
        let options = JsType.bridge(
            ["acceptAllAdvertisements": true]
        )
        let decoded = try #require(decodeStartRequest(["options": options]))
        #expect(decoded.acceptAllAdvertisements == true)
    }

    @Test
    func decode_optionsWithKeepRepeatedDevicesTrue_succeeds() throws {
        let options = JsType.bridge(
            ["keepRepeatedDevices": true]
        )
        let decoded = try #require(decodeStartRequest(["options": options]))
        #expect(decoded.keepRepeatedDevices == true)
    }

    @Test
    func decode_optionsWithFilters_succeeds() throws {
        let options = JsType.bridge(
            ["filters": [["name": "Slartibartfast"]]]
        )
        let decoded = try #require(decodeStartRequest(["options": options]))
        let filters = try decoded.decodeAndValidateFilters()
        #expect(filters.count == 1)
    }

    @Test
    func decode_stopWithoutId_returnsNil() {
        let data = ["stop": JsType.bridge(true)]
        let request = RequestLEScanRequest.decode(from: data)
        #expect(request == nil)
    }

    @Test
    func decode_stopWithId_succeeds() throws {
        let data: [String: JsType] = [
            "stop": .number(true),
            "scanId": .string("123"),
        ]
        let scanId = try #require(decodeStopRequest(data))
        #expect(scanId == "123")
    }
}

@Suite(.tags(.requestLEScan))
struct RequestLEScanResponseResponseTests {
    @Test
    func toJsMessage_withStopResponse_hasExpectedBody() throws {
        let sut = RequestLEScanResponse.stop
        let jsMessage = sut.toJsMessage()
        let body = try #require(jsMessage.extractBody(as: NSDictionary.self))
        #expect(body == ["active": false])
    }

    @Test
    func toJsMessage_withStartResponse_hasExpectedBody() throws {
        let scan = BluetoothLEScan(filters: [], keepRepeatedDevices: false, acceptAllAdvertisements: true, active: true)
        let sut = RequestLEScanResponse.start(id: "123", scan: scan)
        let jsMessage = sut.toJsMessage()
        let body = try #require(jsMessage.extractBody(as: NSDictionary.self))
        #expect((body["scanId"] as? String) == "123")
        #expect((body["active"] as? Bool) == true)
        #expect((body["acceptAllAdvertisements"] as? Bool) == true)
        #expect((body["keepRepeatedDevices"] as? Bool) == false)
    }
}

@Suite(.tags(.requestLEScan))
struct RequestLEScanRequestValidationTests {
    @Test
    func decodeAndValidateFilters_withNameFilter_succeeds() throws {
        let options = JsType.bridge(
            ["filters": [["name": "Slartibartfast"]]]
        )
        let sut = try #require(decodeStartRequest(["options": options]))
        let filters = try sut.decodeAndValidateFilters()
        #expect(filters[0].name == "Slartibartfast")
    }

    @Test
    func decodeAndValidateFilters_withAcceptAllAdvertisementsTrueAndNonEmptyFilters_throws() throws {
        let options = JsType.bridge(
            [
                "acceptAllAdvertisements": true,
                "filters": [["name": "Slartibartfast"]],
            ]
        )
        let sut = try #require(decodeStartRequest(["options": options]))
        #expect(throws: OptionsError.invalidInput("Cannot set acceptAllAdvertisements to true if filters are provided")) {
            try sut.decodeAndValidateFilters()
        }
    }

    @Test
    func decodeAndValidateFilters_withAcceptAllAdvertisementsFalseAndEmptyFilters_throws() throws {
        let options = JsType.bridge(
            [
                "acceptAllAdvertisements": false,
                "filters": [],
            ]
        )
        let sut = try #require(decodeStartRequest(["options": options]))
        #expect(throws: OptionsError.invalidInput("Cannot set acceptAllAdvertisements to false without providing filters")) {
            try sut.decodeAndValidateFilters()
        }
    }
}

private func decodeStartRequest(_ data: [String: JsType]?) -> RequestLEScanOptions? {
    switch RequestLEScanRequest.decode(from: data) {
    case let .some(.start(options)): options
    default: nil
    }
}

private func decodeStopRequest(_ data: [String: JsType]?) -> String? {
    switch RequestLEScanRequest.decode(from: data) {
    case let .some(.stop(id)): id
    default: nil
    }
}
