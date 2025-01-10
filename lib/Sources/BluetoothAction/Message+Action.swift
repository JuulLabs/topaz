import Bluetooth
import BluetoothClient
import BluetoothMessage
import DevicePicker
import JsMessage

extension Message {
    public func buildAction(client: BluetoothClient, selector: any InteractiveDeviceSelector) -> Result<any BluetoothAction, Error> {
        switch action {
        case .getAvailability:
            return Availability.create(from: self)
        case .requestDevice:
            return RequestDeviceRequest.decode(from: self).map {
                RequestDevice(request: $0, selector: selector)
            }
        case .connect:
            return Connector.create(from: self)
        case .disconnect:
            return Disconnector.create(from: self)
        case .discoverServices:
            return DiscoverServices.create(from: self)
        case .discoverCharacteristics:
            return DiscoverCharacteristics.create(from: self)
        case .readCharacteristic:
            return ReadCharacteristic.create(from: self)
        case .startNotifications:
            return StartNotifications.create(from: self)
        }
    }
}
