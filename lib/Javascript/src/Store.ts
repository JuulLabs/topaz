import type { BluetoothDevice } from "./BluetoothDevice";
import type { BluetoothRemoteGATTCharacteristic } from "./BluetoothRemoteGATTCharacteristic";
import type { BluetoothRemoteGATTDescriptor } from "./BluetoothRemoteGATTDescriptor";
import type { BluetoothRemoteGATTService } from "./BluetoothRemoteGATTService";

type CharacteristicKey = string

type CharacteristicRecord = {
    uuid: string;
    characteristic: BluetoothRemoteGATTCharacteristic;
    descriptors: Map<string, BluetoothRemoteGATTDescriptor>;
}

type ServiceRecord = {
    uuid: string;
    service: BluetoothRemoteGATTService;
    characteristics: Map<CharacteristicKey, CharacteristicRecord>;
}

type DeviceRecord = {
    uuid: string;
    device: BluetoothDevice;
    services: Map<string, ServiceRecord>;
}

const characteristicKey = (uuid: string, instance: number): CharacteristicKey => {
    return uuid + '.' + instance;
}

const keyForCharacteristic = (characteristic: BluetoothRemoteGATTCharacteristic): CharacteristicKey => {
    return characteristicKey(characteristic.uuid, characteristic.instance);
}

class Store {
    #devices: Map<string, DeviceRecord>;

    constructor() {
        this.#devices = new Map();
    }

    getDevice = (uuid: string): BluetoothDevice | undefined => {
        return this.#devices.get(uuid)?.device;
    }

    addDevice = (device: BluetoothDevice) => {
        const deviceRecord = this.#devices.get(device.uuid);
        if (deviceRecord) {
            // Perform any cleanup necessary here
        }
        this.#devices.set(device.uuid, { uuid: device.uuid, device, services: new Map() });
    }

    getService = (deviceUuid: string, serviceUuid: string): BluetoothRemoteGATTService | undefined => {
        return this.#devices.get(deviceUuid)?.services.get(serviceUuid)?.service;
    }

    addService = (service: BluetoothRemoteGATTService) => {
        const deviceRecord = this.#devices.get(service.device.uuid);
        if (!deviceRecord) {
            throw new ReferenceError(`Device ${service.device.uuid} not found`);
        }
        deviceRecord.services.set(service.uuid, { uuid: service.uuid, service, characteristics: new Map() });
    }

    getCharacteristic = (service: BluetoothRemoteGATTService, uuid: string, instance: number): BluetoothRemoteGATTCharacteristic | undefined => {
        return this.#devices.get(service.device.uuid)?.services.get(service.uuid)?.characteristics.get(characteristicKey(uuid, instance))?.characteristic;
    }

    addCharacteristic = (service: BluetoothRemoteGATTService, characteristic: BluetoothRemoteGATTCharacteristic) => {
        const serviceRecord = this.#devices.get(service.device.uuid)?.services.get(service.uuid);
        if (!serviceRecord) {
            throw new ReferenceError(`Service ${service.uuid} not found`);
        }
        serviceRecord.characteristics.set(keyForCharacteristic(characteristic), { uuid: characteristic.uuid, characteristic, descriptors: new Map() });
    }

    private findCharacteristic = (key: CharacteristicKey): BluetoothRemoteGATTCharacteristic | undefined => {
        for (const deviceRecord of this.#devices.values()) {
            for (const serviceRecord of deviceRecord.services.values()) {
                const characteristic = serviceRecord.characteristics.get(key)?.characteristic;
                if (characteristic) {
                    return characteristic;
                }
            }
        }
        return undefined;
    }

    updateCharacteristicValue = (key: CharacteristicKey, value: DataView): BluetoothRemoteGATTCharacteristic => {
        const characteristic = this.findCharacteristic(key);
        if (!characteristic) {
            throw new ReferenceError(`Characteristic ${key} not found`);
        }
        characteristic.value = value;
        return characteristic;
    }

    getDescriptor = (characteristic: BluetoothRemoteGATTCharacteristic, uuid: string): BluetoothRemoteGATTDescriptor | undefined => {
        return this.#devices
            .get(characteristic.service.device.uuid)
            ?.services
            .get(characteristic.service.uuid)
            ?.characteristics
            .get(characteristicKey(characteristic.uuid, characteristic.instance))
            ?.descriptors
            .get(uuid)
    }

    addDescriptor = (characteristic: BluetoothRemoteGATTCharacteristic, descriptor: BluetoothRemoteGATTDescriptor) => {
        const characteristicRecord = this.#devices
            .get(characteristic.service.device.uuid)
            ?.services
            .get(characteristic.service.uuid)
            ?.characteristics
            .get(keyForCharacteristic(characteristic))
        if (!characteristicRecord) {
            throw new ReferenceError(`Characteristic ${characteristic.uuid} not found`);
        }
        characteristicRecord.descriptors.set(descriptor.uuid, descriptor);
    }
}

export const store = new Store();
