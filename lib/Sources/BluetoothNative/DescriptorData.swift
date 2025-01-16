import Foundation

enum CBDescriptorDecodeError: Error, Equatable {
    case noData
    case unableToEncodeStringAsData(String)
    case unsupportedValueType(String)
}

extension CBDescriptorDecodeError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noData:
            return "todo"
        case let .unableToEncodeStringAsData(hexDump):
            return "Failed to encode descriptor string value as UTF8 Data: \(hexDump)"
        case let .unsupportedValueType(type):
            return "Unsupported descriptor value type: \(type)"
        }
    }
}

/* | Core Bluetooth Descriptor UUID                | `value` type      | Core Specification v6[^1] |
 * |-----------------------------------------------|-------------------|---------------------------|
 * | CBUUIDCharacteristicExtendedPropertiesString  | NSNumber (2-bits) | Vol 3, Part G, 3.3.3.1    |
 * | CBUUIDCharacteristicUserDescriptionString     | NSString (UTF-8)  | Vol 3, Part G, 3.3.3.2    |
 * | CBUUIDClientCharacteristicConfigurationString | NSNumber (2-bits) | Vol 3, Part G, 3.3.3.3    |
 * | CBUUIDServerCharacteristicConfigurationString | NSNumber (1-bit)  | Vol 3, Part G, 3.3.3.4    |
 * | CBUUIDCharacteristicFormatString              | NSData (7-octets) | Vol 3, Part G, 3.3.3.5    |
 * | CBUUIDCharacteristicAggregateFormatString     | NSData            | Vol 3, Part G, 3.3.3.6    |
 * | CBUUIDL2CAPPSMCharacteristicString            | UInt16            |                           |
 *
 * [^1]: https://www.bluetooth.com/specifications/specs/core-specification-6-0/
 */
func descriptorData(_ value: Any?) -> Result<Data, any Error> {
    let result: Data
    switch value {
    case let data as NSData:
        result = Data(data)
    case let data as NSString:
        guard let encoded = data.data(using: NSUTF8StringEncoding) else {
            // Use `String.UTF8View` here to get a byte representation we can dump out
            let hexDump = (data as String).utf8.hexEncodedString()
            return .failure(CBDescriptorDecodeError.unableToEncodeStringAsData(hexDump))
        }
        result = encoded
    case let data as NSNumber:
        result = withUnsafeBytes(of: data.uint16Value) { Data($0) }
    case let data as UInt16:
        result = withUnsafeBytes(of: data) { Data($0) }
    case .none:
        return .failure(CBDescriptorDecodeError.noData)
    case let .some(value):
        return .failure(CBDescriptorDecodeError.unsupportedValueType(String(describing: value)))
    }
    return .success(result)
}
