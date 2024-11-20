@testable import BluetoothNative
import CoreBluetooth
import Testing

struct CbUuidTests {

    @Test
    func regularUuid_withUInt16Alias_expandsTo16ByteBluetoothUuid() {
        let batteryService: UInt16 = 0x180F
        let batteryServiceData = withUnsafeBytes(of: batteryService.bigEndian) { Data($0) }
        let sut = CBUUID(data: batteryServiceData)
        #expect(sut.uuidString == "180F")
        #expect(sut.regularUuid.uuidString == "0000180F-0000-1000-8000-00805F9B34FB")
    }

    @Test
    func regularUuid_withUInt32Alias_expandsTo16ByteBluetoothUuid() {
        // 32bit alias range is not in use yet and is reserved for when the 16bit space is exhausted
        let fakeService: UInt32 = 0x133F180F
        let fakeData = withUnsafeBytes(of: fakeService.bigEndian) { Data($0) }
        let sut = CBUUID(data: fakeData)
        #expect(sut.uuidString == "133F180F")
        #expect(sut.regularUuid.uuidString == "133F180F-0000-1000-8000-00805F9B34FB")
    }

    @Test
    func regularUuid_withFullSizeUuid_encodesDirectly() throws {
        let batteryService = Data([0x00, 0x00, 0x18, 0x0F, 0x00, 0x00, 0x10, 0x00, 0x80, 0x00, 0x00, 0x80, 0x5F, 0x9B, 0x34, 0xFB])
        let sut = CBUUID(data: batteryService)
        #expect(sut.uuidString == "0000180F-0000-1000-8000-00805F9B34FB")
        #expect(sut.regularUuid.uuidString == "0000180F-0000-1000-8000-00805F9B34FB")
    }

}
