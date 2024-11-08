import { BluetoothCharacteristicProperties } from "./BluetoothCharacteristicProperties";
import { BluetoothDevice } from "./BluetoothDevice";
import { BluetoothRemoteGATTCharacteristic } from "./BluetoothRemoteGATTCharacteristic";
import { BluetoothRemoteGATTService } from "./BluetoothRemoteGATTService";

type ServiceRecord = {
    uuid: string;
    service: BluetoothRemoteGATTService;
    characteristics: Map<string, BluetoothRemoteGATTCharacteristic>;
}

type DeviceRecord = {
    uuid: string;
    device: BluetoothDevice;
    services: Map<string, ServiceRecord>;
}

class Store {
    private devices = new Map<string, DeviceRecord>()

    constructor() {}

    getOrCreateDevice = (uuid: string, name?: string): BluetoothDevice => {
        const deviceRecord = this.devices.get(uuid);
        if (deviceRecord) {
            return deviceRecord.device;
        }
        const device = new BluetoothDevice(uuid, name);
        this.devices.set(uuid, { uuid, device, services: new Map() });
        return device;
    }

    getOrCreateService = (device: BluetoothDevice, uuid: string, isPrimary: boolean): BluetoothRemoteGATTService => {
        const deviceRecord = this.devices.get(device.uuid);
        if (!deviceRecord) {
            throw new ReferenceError(`Device ${device.uuid} not found in store`);
        }
        const serviceRecord = deviceRecord.services.get(uuid);
        if (serviceRecord) {
            return serviceRecord.service;
        }
        const service = new BluetoothRemoteGATTService(device, uuid, isPrimary);
        deviceRecord.services.set(uuid, { uuid, service, characteristics: new Map() });
        return service;
    }

    getOrCreateCharacteristic = (service: BluetoothRemoteGATTService, uuid: string, properties: BluetoothCharacteristicProperties): BluetoothRemoteGATTCharacteristic => {
        const deviceRecord = this.devices.get(service.device.uuid);
        if (!deviceRecord) {
            throw new ReferenceError(`Device ${service.device.uuid} not found in store`);
        }
        const serviceRecord = deviceRecord.services.get(service.uuid);
        if (!serviceRecord) {
            throw new ReferenceError(`Service ${service.uuid} not found in store`);
        }
        const cachedCharacteristic = serviceRecord.characteristics.get(uuid);
        if (cachedCharacteristic) {
            return cachedCharacteristic;
        }
        const characteristic = new BluetoothRemoteGATTCharacteristic(service, uuid, properties);
        serviceRecord.characteristics.set(uuid, characteristic);
        return characteristic;
    }
}

export const store = new Store();
