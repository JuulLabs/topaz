import Bluetooth
import Foundation

public typealias DeviceIdentifier = UUID
public typealias ServiceIdentifier = UUID
public typealias CharacteristicIdentifier = UUID

/**
 Models the Web Bluetooth API as Sendable data.
 https://developer.mozilla.org/en-US/docs/Web/API/Web_Bluetooth_API

 Note that all the actual Javascript objects live only within the context of a web page which is
 beyond our process boundary. Here in native-land we can only model the messaging surface. We mimic
 the API and replace parameterized objects with serializable references (e.g. UUIDs mostly).
 */

/**
 Models API calls made by the executing Javascript application.
 */
public enum WebBluetoothRequest: Sendable {
    // General
    case getAvailability
    case requestDevice(Filter)

    // GATT Server
    case connect(DeviceIdentifier)
    case disconnect(DeviceIdentifier)
    case getPrimaryService(DeviceIdentifier, ServiceIdentifier)
    case getPrimaryServices(DeviceIdentifier, ServiceIdentifier)

    // GATT Service
    case getCharacteristic(DeviceIdentifier, ServiceIdentifier, CharacteristicIdentifier)
    case getCharacteristics(DeviceIdentifier, ServiceIdentifier, CharacteristicIdentifier)

    // GATT Characteristic
    // TODO: moar descriptors, start/stop notifications, read/write value
}

/**
 Models return values to `WebBluetoothRequest` API calls.
 */
public enum WebBluetoothResponse: Sendable {
    case availability(Bool)
    case device(DeviceIdentifier)
    case service(DeviceIdentifier, ServiceIdentifier)
    case services(DeviceIdentifier, [ServiceIdentifier])
    case characteristic(DeviceIdentifier, ServiceIdentifier, CharacteristicIdentifier)
    case characteristics(DeviceIdentifier, ServiceIdentifier, [CharacteristicIdentifier])
    // TODO: moar characteristic stuff like read/write
}

/**
 Models out-of-band Bluetooth API events.
 */
public enum WebBluetoothEvent: Sendable {
    case disconnected(DeviceIdentifier)
    case characteristicValue(DeviceIdentifier, ServiceIdentifier, CharacteristicIdentifier, Data)
    // TODO: moar events, availability state, what else?
}
