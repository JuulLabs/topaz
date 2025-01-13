@testable import BluetoothNative
import Foundation
import Testing
import XCTest

extension Tag {
    @Tag static var descriptors: Self
}
@Suite(.tags(.descriptors))
struct DescriptorDataTests {

    /**
     Core Bluetooth provides descriptor read value as `NSString` for the following descriptors:
     - [CBUUIDCharacteristicUserDescriptionString](https://developer.apple.com/documentation/corebluetooth/cbuuidcharacteristicuserdescriptionstring)
     */
    @Test
    func descriptorData_withNSString_returnsUTF8RepresentationAsData() throws {
        let string: NSString = "test"
        let result = descriptorData(string)
        let expected = Data([0x74, 0x65, 0x73, 0x74]) // "test"
        #expect(try result.get() == expected)
    }

    @Test
    func descriptorData_withNonUTF8NSString_returnsError() {
        let latin1Data: Data = Data([0x48, 0x65, 0x6C, 0x6C, 0xF6]) // "Hellö" in ISO Latin 1
        let string = NSString(data: latin1Data, encoding: String.Encoding.isoLatin1.rawValue)
        let result = descriptorData(string)
        XCTAssertThrowsError(try result.get()) { error in
            XCTAssertEqual(error as? CBDescriptorDecodeError, CBDescriptorDecodeError.unableToEncodeStringAsData("Hellö"))
        }
    }

    /**
     Core Bluetooth provides descriptor read value as `NSNumber` for the following descriptors:
     - [CBUUIDCharacteristicExtendedPropertiesString](https://developer.apple.com/documentation/corebluetooth/cbuuidcharacteristicextendedpropertiesstring)
     - [CBUUIDClientCharacteristicConfigurationString](https://developer.apple.com/documentation/corebluetooth/cbuuidclientcharacteristicconfigurationstring)
     - [CBUUIDServerCharacteristicConfigurationString](https://developer.apple.com/documentation/corebluetooth/cbuuidservercharacteristicconfigurationstring)
     
     Per Core Specification v6, Vol 3, Part G, 3.3.3.1, "Table 3.8: Characteristic Extended Properties bit field":
     
     | Bit number | Property             |
     |------------|----------------------|
     |      0     | Reliable Write       |
     |      1     | Writable Auxiliaries |
     
     Per Core Specification v6, Vol 3, Part G, 3.3.3.3, "Table 3.11: Client Characteristic Configuration bit field definition":
     
     | Bit number | Property     |
     |------------|--------------|
     |      0     | Notification |
     |      1     | Indication   |
     
     Per Core Specification v6, Vol 3, Part G, 3.3.3.4, "Table 3.13: Server Characteristic Configuration bit field definition":
     
     | Bit number | Property  |
     |------------|-----------|
     |      0     | Broadcast |
     */
    @Test
    func descriptorData_withNSNumber_returnsUInt16RepresentationAsData() throws {
        let bits: UInt16 = 0b11
        let number = NSNumber(value: bits)
        let result = descriptorData(number)
        #expect(try result.get() == Data([0x03, 0x00]))
    }

    /**
     Core Bluetooth provides descriptor read value as `NSData` for the following descriptors:
     - [CBUUIDCharacteristicFormatString](https://developer.apple.com/documentation/corebluetooth/cbuuidcharacteristicformatstring)
     - [CBUUIDCharacteristicAggregateFormatString](https://developer.apple.com/documentation/corebluetooth/cbuuidcharacteristicaggregateformatstring)
     
     Per Core Specification v6, Vol 3, Part G, 3.3.3.5, "Table 3.15: Characteristic Presentation Format value definition":
     
     | Field Name  | Value Size |
     |-------------|------------|
     | Format      | 1 octet    |
     | Exponent    | 1 octet    |
     | Unit        | 2 octets   |
     | Name Space  | 1 octet    |
     | Description | 2 octets   |
     */
    @Test
    func descriptorData_withNSData_returnsData() throws {
        let test = Data([
            0x01,       // Format
            0x02,       // Exponent
            0x03, 0x04, // Unit
            0x05,       // Name Space
            0x06, 0x07, // Description
        ])
        let input = NSData(data: test)
        let result = descriptorData(input)
        #expect(try result.get() == test)
    }

    /**
     Core Bluetooth provides descriptor read value as `UInt16` for the following descriptors:
     - [CBUUIDL2CAPPSMCharacteristicString](https://developer.apple.com/documentation/corebluetooth/cbuuidl2cappsmcharacteristicstring)
     */
    @Test
    func descriptorData_withUInt16_returnsUInt16RepresentationAsData() throws {
        let value: UInt16 = 0b1
        let result = descriptorData(value)
        #expect(try result.get() == Data([0x01, 0x00]))
    }

    @Test
    func descriptorData_withUUID_returnsError() {
        let input = UUID(uuidString: "5c80529a-aad1-4caf-a0e7-10a2b04478d5")
        let result = descriptorData(input)
        XCTAssertThrowsError(try result.get()) { error in
            XCTAssertEqual(error as? CBDescriptorDecodeError, CBDescriptorDecodeError.unsupportedValueType("UUID"))
        }
    }
}
