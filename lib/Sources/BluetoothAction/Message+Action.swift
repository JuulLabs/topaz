import Bluetooth
import BluetoothClient
import BluetoothMessage
import DevicePicker
import JsMessage

extension Message {
    public func buildAction(
        client: BluetoothClient,
        selector: any InteractiveDeviceSelector,
        jsEventForwarder: JsEventForwarder
    ) -> Result<any BluetoothAction, Error> {
        switch action {

        // General
        case .getAvailability:
            return Availability.create(from: self)
        case .getDevices:
            return GetDevices.create(from: self)
        case .requestDevice:
            return RequestDeviceRequest.decode(from: self).map {
                RequestDevice(request: $0, selector: selector)
            }
        case .requestLEScan:
            return RequestLEScanRequest.decode(from: self).map {
                RequestLEScan(request: $0, jsEventForwarder: jsEventForwarder)
            }

        // BluetoothDevice
        case .forgetDevice:
            return ForgetDevice.create(from: self)
        case .watchAdvertisements:
            return WatchAdvertisementsRequest.decode(from: self).map {
                WatchAdvertisements(request: $0, jsEventForwarder: jsEventForwarder)
            }

        // GATT Server
        case .connect:
            return Connector.create(from: self)
        case .disconnect:
            return Disconnector.create(from: self)
        case .discoverServices:
            return DiscoverServices.create(from: self)

        // GATT Service
        case .discoverCharacteristics:
            return DiscoverCharacteristics.create(from: self)

        // GATT Characteristic
        case .discoverDescriptors:
            return DiscoverDescriptors.create(from: self)
        case .readCharacteristic:
            return ReadCharacteristic.create(from: self)
        case .writeCharacteristic:
            return WriteCharacteristic.create(from: self)
        case .startNotifications:
            return StartNotifications.create(from: self)
        case .stopNotifications:
            return StopNotifications.create(from: self)

        // GATT Descriptor
        case .readDescriptor:
            return ReadDescriptor.create(from: self)
        }
    }
}
