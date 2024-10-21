import Bluetooth
import CoreBluetooth
import Testing

struct CharacteristicPropertiesTests {

    @Test(arguments: [
        (CBCharacteristicProperties.broadcast, CharacteristicProperties.broadcast),
        (CBCharacteristicProperties.read, CharacteristicProperties.read),
        (CBCharacteristicProperties.writeWithoutResponse, CharacteristicProperties.writeWithoutResponse),
        (CBCharacteristicProperties.write, CharacteristicProperties.write),
        (CBCharacteristicProperties.notify, CharacteristicProperties.notify),
        (CBCharacteristicProperties.indicate, CharacteristicProperties.indicate),
        (CBCharacteristicProperties.authenticatedSignedWrites, CharacteristicProperties.authenticatedSignedWrites),
        (CBCharacteristicProperties.extendedProperties, CharacteristicProperties.extendedProperties),
        (CBCharacteristicProperties.notifyEncryptionRequired,CharacteristicProperties.notifyEncryptionRequired),
        (CBCharacteristicProperties.indicateEncryptionRequired, CharacteristicProperties.indicateEncryptionRequired),
    ])
    func init_usingCoreBluetoothRawValue_matchesCorrespondingElement(
        pair: (CBCharacteristicProperties, CharacteristicProperties)
    ) {
        let native: CBCharacteristicProperties = pair.0
        let shadow: CharacteristicProperties = pair.1
        let sut = CharacteristicProperties.init(rawValue: native.rawValue)
        #expect(sut == shadow)
    }
}
