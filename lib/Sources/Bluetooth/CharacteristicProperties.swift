
/**
 Shadows CBCharacteristicProperties
 */
public struct CharacteristicProperties : OptionSet, Equatable, Sendable {

    public let rawValue: UInt

    public static let broadcast = CharacteristicProperties(rawValue: 1 << 0)
    public static let read = CharacteristicProperties(rawValue: 1 << 1)
    public static let writeWithoutResponse = CharacteristicProperties(rawValue: 1 << 2)
    public static let write = CharacteristicProperties(rawValue: 1 << 3)
    public static let notify = CharacteristicProperties(rawValue: 1 << 4)
    public static let indicate = CharacteristicProperties(rawValue: 1 << 5)
    public static let authenticatedSignedWrites = CharacteristicProperties(rawValue: 1 << 6)
    public static let extendedProperties = CharacteristicProperties(rawValue: 1 << 7)
    public static let notifyEncryptionRequired = CharacteristicProperties(rawValue: 1 << 8)
    public static let indicateEncryptionRequired = CharacteristicProperties(rawValue: 1 << 9)

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
}
