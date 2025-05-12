import Bluetooth
@testable import BluetoothAction
import BluetoothClient
import BluetoothMessage
import Foundation
import JsMessage
import Testing

extension Tag {
    @Tag static var watchAdvertisements: Self
}

@Suite(.tags(.watchAdvertisements))
struct WatchAdvertisementsRequestTests {

    @Test
    func decode_withValidInputs_succeeds() {
        let uuid = UUID(n: 0)
        let body: [String: JsType] = [
            "enable": .number(true),
            "uuid": .string(uuid.uuidString),
        ]
        let request = WatchAdvertisementsRequest.decode(from: body)
        #expect(request?.enable == true)
        #expect(request?.peripheralId == uuid)
    }

    @Test
    func decode_withEnableFlagMissing_isNil() {
        let uuid = UUID(n: 0)
        let body: [String: JsType] = [
            "uuid": .string(uuid.uuidString),
        ]
        let request = WatchAdvertisementsRequest.decode(from: body)
        #expect(request == nil)
    }

    @Test
    func decode_withUuidMissing_isNil() {
        let body: [String: JsType] = [
            "enable": .number(true),
        ]
        let request = WatchAdvertisementsRequest.decode(from: body)
        #expect(request == nil)
    }

    @Test
    func decode_withInvalidUuid_isNil() {
        let body: [String: JsType] = [
            "enable": .number(true),
            "uuid": .string("bananaman"),
        ]
        let request = WatchAdvertisementsRequest.decode(from: body)
        #expect(request == nil)
    }

    @Test
    func decode_withEmptyBody_isNil() {
        let body: [String: JsType] = [:]
        let request = WatchAdvertisementsRequest.decode(from: body)
        #expect(request == nil)
    }
}
