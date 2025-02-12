import { BluetoothDevice } from "./BluetoothDevice";
import { bluetoothRequest } from "./WebKit";
import { BluetoothRemoteGATTCharacteristic } from "./BluetoothRemoteGATTCharacteristic";
import { BluetoothCharacteristicProperties } from "./BluetoothCharacteristicProperties";
import { store } from "./Store";
import { BluetoothUUID } from "./BluetoothUUID";

type DiscoverCharacteristicsRequest = {
    device: string;
    service: string;
    characteristic: string;
    single: boolean;
}

type Characteristic = {
    uuid: string;
    instance: number;
    properties: BluetoothCharacteristicProperties;
}

type DiscoverCharacteristicsResponse = {
    characteristics: Characteristic[];
}

const getOrCreateCharacteristic = (
    service: BluetoothRemoteGATTService,
    uuid: string,
    properties: BluetoothCharacteristicProperties,
    instance: number
): BluetoothRemoteGATTCharacteristic => {
    const existingCharacteristic = store.getCharacteristic(service, uuid, instance);
    if (existingCharacteristic) {
        return existingCharacteristic;
    }
    const characteristic = new BluetoothRemoteGATTCharacteristic(service, uuid, properties, instance);
    store.addCharacteristic(service, characteristic);
    return characteristic;
}

// https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTService
export class BluetoothRemoteGATTService extends EventTarget {
    device: BluetoothDevice;
    uuid: string;
    isPrimary: boolean;

    constructor(device: BluetoothDevice, uuid: string, isPrimary: boolean) {
        super();
        this.device = device;
        this.uuid = uuid;
        this.isPrimary = isPrimary;
    }

    /**
     * Loosely models the `GetGATTChildren` function as described in the Web Bluetooth Specification:
     * https://webbluetoothcg.github.io/web-bluetooth/#bluetoothgattservice-interface
     *
     * ```
     * Return GetGATTChildren(attribute=this,
     *                        single=<boolean>,
     *                        uuidCanonicalizer=BluetoothUUID.getCharacteristic,
     *                        uuid=characteristic,
     *                        allowedUuids=undefined,
     *                        child type="GATT Characteristic")
     * ```
     */
    private GetGATTChildren = async (single: boolean, characteristic?: string | number): Promise<BluetoothRemoteGATTCharacteristic[]> => {
        const response = await bluetoothRequest<DiscoverCharacteristicsRequest, DiscoverCharacteristicsResponse>(
            'discoverCharacteristics',
            {
                device: this.device.id,
                service: this.uuid,
                characteristic: characteristic ? BluetoothUUID.getCharacteristic(characteristic) : null,
                single: single
            }
        );
        return response.characteristics.map(characteristic =>
            getOrCreateCharacteristic(this, characteristic.uuid, characteristic.properties, characteristic.instance)
        );
    }

    // https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTService/getCharacteristic
    getCharacteristic = async (characteristic?: string | number): Promise<BluetoothRemoteGATTCharacteristic> => {
        if (typeof characteristic === "undefined") {
            throw new TypeError("Missing 'characteristic' UUID parameter.")
        }
        const characteristics = await this.GetGATTChildren(true, characteristic)
        return characteristics[0]
    }

    // https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTService/getCharacteristics
    getCharacteristics = async (characteristic?: string | number): Promise<BluetoothRemoteGATTCharacteristic[]> => {
        return this.GetGATTChildren(false, characteristic)
    }

    // TODO:
}
