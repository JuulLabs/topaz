import { BluetoothDevice } from "./BluetoothDevice";
import { bluetoothRequest } from "./WebKit";
import { BluetoothRemoteGATTCharacteristic } from "./BluetoothRemoteGATTCharacteristic";
import { BluetoothCharacteristicProperties } from "./BluetoothCharacteristicProperties";

type DiscoverCharacteristicsRequest = {
    uuid: string;
    service: string;
    characteristic: string;
    single: boolean;
}

type Characteristic = {
    uuid: string;
    properties: BluetoothCharacteristicProperties;
}

type DiscoverCharacteristicsResponse = {
    characteristics: Characteristic[];
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
    private GetGATTChildren = async (single: boolean, characteristic?: string): Promise<Array<BluetoothRemoteGATTCharacteristic>> => {
        const response = await bluetoothRequest<DiscoverCharacteristicsRequest, DiscoverCharacteristicsResponse>(
            'discoverCharacteristics',
            {
                uuid: this.device.uuid,
                service: this.uuid,
                characteristic: characteristic,
                single: single
            }
        );
        return response.characteristics.map(characteristic =>
            new BluetoothRemoteGATTCharacteristic(this, characteristic.uuid, characteristic.properties)
        );
    }

    // https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTService/getCharacteristic
    getCharacteristic = async (characteristic?: string): Promise<BluetoothRemoteGATTCharacteristic> => {
        if (typeof characteristic === "undefined") {
            throw new TypeError("Missing 'characteristic' UUID parameter.")
        }
        const characteristics = await this.GetGATTChildren(true, characteristic)
        return characteristics[0]
    }

    // https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTService/getCharacteristics
    getCharacteristics = async (characteristic?: string): Promise<BluetoothRemoteGATTCharacteristic[]> => {
        return this.GetGATTChildren(false, characteristic)
    }

    // TODO:
}
