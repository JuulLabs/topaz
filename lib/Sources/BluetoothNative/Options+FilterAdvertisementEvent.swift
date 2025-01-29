import Bluetooth
import BluetoothClient

extension Options {
    func includeAdvertisementEventInDeviceList(_ advertisementEvent: AdvertisementEvent) -> Bool {
        return true
    }
}
