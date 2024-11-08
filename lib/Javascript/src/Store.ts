import { BluetoothCharacteristicProperties } from "./BluetoothCharacteristicProperties";
import { BluetoothDevice } from "./BluetoothDevice";
import { BluetoothRemoteGATTCharacteristic } from "./BluetoothRemoteGATTCharacteristic";
import { BluetoothRemoteGATTService } from "./BluetoothRemoteGATTService";
import { mainDispatcher } from "./EventDispatcher";

type CharacteristicKey = string

type ServiceRecord = {
    uuid: string;
    service: BluetoothRemoteGATTService;
    characteristics: Map<CharacteristicKey, BluetoothRemoteGATTCharacteristic>;
}

type DeviceRecord = {
    uuid: string;
    device: BluetoothDevice;
    services: Map<string, ServiceRecord>;
}

export const characteristicKey = (uuid: string, instance: number): CharacteristicKey => {
    return uuid + '.' + instance;
}

class Store {
    private devices = new Map<string, DeviceRecord>()

    constructor() {}

    createDevice = (uuid: string, name?: string): BluetoothDevice => {
        const deviceRecord = this.devices.get(uuid);
        if (deviceRecord) {
            mainDispatcher.removeTarget(deviceRecord.device.uuid, 'gattserverdisconnected');
        }
        const device = new BluetoothDevice(uuid, name);
        this.devices.set(uuid, { uuid, device, services: new Map() });
        return device;
    }

    getOrCreateService = (device: BluetoothDevice, uuid: string, isPrimary: boolean): BluetoothRemoteGATTService => {
        const deviceRecord = this.devices.get(device.uuid);
        if (!deviceRecord) {
            throw new ReferenceError(`Device ${device.uuid} not found`);
        }
        const serviceRecord = deviceRecord.services.get(uuid);
        if (serviceRecord) {
            return serviceRecord.service;
        }
        const service = new BluetoothRemoteGATTService(device, uuid, isPrimary);
        deviceRecord.services.set(uuid, { uuid, service, characteristics: new Map() });
        return service;
    }

    getOrCreateCharacteristic = (service: BluetoothRemoteGATTService, uuid: string, properties: BluetoothCharacteristicProperties, instance: number): BluetoothRemoteGATTCharacteristic => {
        const deviceRecord = this.devices.get(service.device.uuid);
        if (!deviceRecord) {
            throw new ReferenceError(`Device ${service.device.uuid} not found`);
        }
        const serviceRecord = deviceRecord.services.get(service.uuid);
        if (!serviceRecord) {
            throw new ReferenceError(`Service ${service.uuid} not found`);
        }
        const key = characteristicKey(uuid, instance);
        const cachedCharacteristic = serviceRecord.characteristics.get(key);
        if (cachedCharacteristic) {
            return cachedCharacteristic;
        }
        const characteristic = new BluetoothRemoteGATTCharacteristic(service, uuid, properties, instance);
        serviceRecord.characteristics.set(key, characteristic);
        return characteristic;
    }

    private findCharacteristic = (key: CharacteristicKey): BluetoothRemoteGATTCharacteristic | undefined => {
        for (const deviceRecord of this.devices.values()) {
            for (const serviceRecord of deviceRecord.services.values()) {
                const characteristic = serviceRecord.characteristics.get(key);
                if (characteristic) {
                    return characteristic;
                }
            }
        }
        return undefined;
    }

    updateCharacteristicValue = (key: CharacteristicKey, value: DataView): void => {
        const characteristic = this.findCharacteristic(key);
        if (!characteristic) {
            throw new ReferenceError(`Characteristic ${key} not found`);
        }
        characteristic.value = value;
    }
}

export const store = new Store();
