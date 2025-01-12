import Foundation

enum CBDescriptorDecodeError: Error, Equatable {
    case unableToEncodeStringAsData(String)
    case unsupportedValueType(String)
}

extension CBDescriptorDecodeError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .unableToEncodeStringAsData(string):
            "Failed to encode '\(string)' as Data"
        case let .unsupportedValueType(type):
            "Unsupported descriptor value type: \(type)"
        }
    }
}

/* | Descriptor UUID                               | `value` type      | Core Specification[^1]     | Core Bluetooth documentation                                                                          |
 * |-----------------------------------------------|-------------------|----------------------------|-------------------------------------------------------------------------------------------------------|
 * | CBUUIDCharacteristicExtendedPropertiesString  | NSNumber (2-bits) | v6, Vol 3, Part G, 3.3.3.1 | https://developer.apple.com/documentation/corebluetooth/cbuuidcharacteristicextendedpropertiesstring  |
 * | CBUUIDCharacteristicUserDescriptionString     | NSString (UTF-8)  | v6, Vol 3, Part G, 3.3.3.2 | https://developer.apple.com/documentation/corebluetooth/cbuuidcharacteristicuserdescriptionstring     |
 * | CBUUIDClientCharacteristicConfigurationString | NSNumber (2-bits) | v6, Vol 3, Part G, 3.3.3.3 | https://developer.apple.com/documentation/corebluetooth/cbuuidclientcharacteristicconfigurationstring |
 * | CBUUIDServerCharacteristicConfigurationString | NSNumber (1-bit)  | v6, Vol 3, Part G, 3.3.3.4 | https://developer.apple.com/documentation/corebluetooth/cbuuidservercharacteristicconfigurationstring |
 * | CBUUIDCharacteristicFormatString              | NSData (7-bytes)  | v6, Vol 3, Part G, 3.3.3.5 | https://developer.apple.com/documentation/corebluetooth/cbuuidcharacteristicformatstring              |
 * | CBUUIDCharacteristicAggregateFormatString     | NSData            | v6, Vol 3, Part G, 3.3.3.6 | https://developer.apple.com/documentation/corebluetooth/cbuuidcharacteristicaggregateformatstring     |
 * | CBUUIDL2CAPPSMCharacteristicString            | UInt16            |                            | https://developer.apple.com/documentation/corebluetooth/cbuuidl2cappsmcharacteristicstring            |
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
            return .failure(CBDescriptorDecodeError.unableToEncodeStringAsData(String(data)))
        }
        result = encoded
    case let data as NSNumber:
        result = withUnsafeBytes(of: data.uint16Value) { Data($0) }
    case let data as UInt16:
        result = withUnsafeBytes(of: data) { Data($0) }
    default:
        return .failure(CBDescriptorDecodeError.unsupportedValueType(String(describing: type(of: value))))
    }
    return .success(result)
}
