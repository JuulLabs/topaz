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
     Per Core Specification v6, Vol 3, Part G, 3.3.3.1:
     
     | Bit number | Property             |
     |------------|----------------------|
     |      0     | Reliable Write       |
     |      1     | Writable Auxiliaries |
     */
    @Test
    func CBUUIDCharacteristicExtendedPropertiesString_NSNumber_success() throws {
        let bits: UInt16 = 0b11
        let number = NSNumber(value: bits)
        let result = descriptorData(number)
        #expect(try result.get() == Data([0x03, 0x00]))
    }

    @Test
    func CBUUIDCharacteristicUserDescriptionString_NSString_success() throws {
        let string = "test"
        let result = descriptorData(string)
        let expected = Data([0x74, 0x65, 0x73, 0x74]) // "test"
        #expect(try result.get() == expected)
    }

    /**
     Per Core Specification v6, Vol 3, Part G, 3.3.3.3:
     
     | Bit number | Property     |
     |------------|--------------|
     |      0     | Notification |
     |      1     | Indication   |
     */
    @Test
    func CBUUIDClientCharacteristicConfigurationString_NSNumber_success() throws {
        let bits: UInt16 = 0b1
        let number = NSNumber(value: bits)
        let result = descriptorData(number)
        #expect(try result.get() == Data([0x01, 0x00]))
    }

    /**
     Per Core Specification v6, Vol 3, Part G, 3.3.3.4:
     
     | Bit number | Property  |
     |------------|-----------|
     |      0     | Broadcast |
     */
    @Test
    func CBUUIDServerCharacteristicConfigurationString_NSNumber_success() throws {
        let bits: UInt16 = 0b1
        let number = NSNumber(value: bits)
        let result = descriptorData(number)
        #expect(try result.get() == Data([0x01, 0x00]))
    }

    /**
     Per Core Specification v6, Vol 3, Part G, 3.3.3.5:
     
     | Field Name  | Value Size |
     |-------------|------------|
     | Format      | 1 octet    |
     | Exponent    | 1 octet    |
     | Unit        | 2 octets   |
     | Name Space  | 1 octet    |
     | Description | 2 octets   |
     */
    @Test
    func CBUUIDCharacteristicFormatString_NSData_success() throws {
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

    @Test
    func CBUUIDL2CAPPSMCharacteristicString_UInt16_success() throws {
        let value: UInt16 = 0b1
        let result = descriptorData(value)
        #expect(try result.get() == Data([0x01, 0x00]))
    }

    @Test
    func unsupportedType_UUID_failure() {
        let input = UUID(uuidString: "5c80529a-aad1-4caf-a0e7-10a2b04478d5")
        let result = descriptorData(input)
        XCTAssertThrowsError(try result.get()) { error in
            XCTAssertEqual(error as? CBDescriptorDecodeError, CBDescriptorDecodeError.unsupportedValueType("UUID"))
        }
    }
}
