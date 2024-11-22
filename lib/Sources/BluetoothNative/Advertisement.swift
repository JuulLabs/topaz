import Bluetooth
import CoreBluetooth

extension Advertisement {
    init(peripheral: CBPeripheral, rssi: NSNumber, data: [String: Any]) {
        self.init(
            peripheralId: peripheral.identifier,
            peripheralName: peripheral.name,
            rssi: rssi.intValue,
            isConnectable: (data[CBAdvertisementDataIsConnectable] as? NSNumber)?.boolValue,
            localName: data[CBAdvertisementDataLocalNameKey] as? String,
            manufacturerData: (data[CBAdvertisementDataManufacturerDataKey] as? Data).flatMap(ManufacturerData.parse),
            overflowServiceUUIDs: uuids(from: data, for: CBAdvertisementDataOverflowServiceUUIDsKey),
            serviceData: ServiceData(extractServiceData(from: data)),
            serviceUUIDs: uuids(from: data, for: CBAdvertisementDataServiceUUIDsKey),
            solicitedServiceUUIDs: uuids(from: data, for: CBAdvertisementDataSolicitedServiceUUIDsKey),
            txPowerLevel: (data[CBAdvertisementDataTxPowerLevelKey] as? NSNumber)?.intValue
        )
    }
}

private func uuids(from dict: [String: Any], for key: String) -> [UUID] {
    (dict[key] as? [CBUUID])?.compactMap(cbToUuid) ?? []
}

private func extractServiceData(from dict: [String: Any]) -> [UUID: Data] {
    (dict[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data])?.reduce(into: [:]) { result, pair in
        result[pair.key.regularUuid] = pair.value
    } ?? [:]
}
