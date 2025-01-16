@testable import BluetoothNative
import Foundation
import Testing

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
    func descriptorData_withUTF16NSString_returnsError() throws {
        let utf16data = Data([0xD8, 0x00]) // Raw bytes representing an unpaired high surrogate (0xD800 in UTF-16).
        let utf16 = NSString(data: utf16data, encoding: String.Encoding.utf16.rawValue)!
        let result = descriptorData(utf16)
        switch result {
        case let .failure(failure):
            let error = try #require(failure as? CBDescriptorDecodeError)
            #expect(error == .unableToEncodeStringAsData("efbfbd"))
        default:
            Issue.record("Unexepected result: \(result)")
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
    func descriptorData_withNil_returnsError() throws {
        let result = descriptorData(nil)
        switch result {
        case let .failure(failure):
            let error = try #require(failure as? CBDescriptorDecodeError)
            #expect(error == .noData)
        default:
            Issue.record("Unexpected result: \(result)")
        }
    }

    @Test
    func descriptorData_withUUID_returnsError() throws {
        let input = UUID(uuidString: "5c80529a-aad1-4caf-a0e7-10a2b04478d5")
        let result = descriptorData(input)
        switch result {
        case let .failure(failure):
            let error = try #require(failure as? CBDescriptorDecodeError)
            #expect(error == .unsupportedValueType("5C80529A-AAD1-4CAF-A0E7-10A2B04478D5"))
        default:
            Issue.record("Unexpected result: \(result)")
        }
    }
}
