import { BluetoothRemoteGATTService } from "./BluetoothRemoteGATTService";
import { BluetoothCharacteristicProperties } from "./BluetoothCharacteristicProperties";

// https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTCharacteristic
export class BluetoothRemoteGATTCharacteristic extends EventTarget {
    service: BluetoothRemoteGATTService;
    uuid: string;
    properties: BluetoothCharacteristicProperties;

    constructor(service: BluetoothRemoteGATTService, uuid: string, properties: BluetoothCharacteristicProperties) {
        super();
        this.service = service;
        this.uuid = uuid;
        this.properties = properties;
    }

    // TODO:
}
