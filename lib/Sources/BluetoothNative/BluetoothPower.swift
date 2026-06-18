import CoreBluetooth

public func liveBluetoothPowerRequest() {
    let options: [String: Any] = [
        CBCentralManagerOptionShowPowerAlertKey: true as NSNumber
    ]
    let _ = CBCentralManager(delegate: nil, queue: nil, options: options)
}
