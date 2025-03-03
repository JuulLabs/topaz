import { BluetoothDevice } from "./BluetoothDevice";
import { bluetoothRequest } from "./WebKit";
import { ValueEvent } from "./ValueEvent";
import { store } from "./Store";
import { BluetoothLEScan, BluetoothLEScanOptions, doRequestLEScan } from "./BluetoothLEScan";

type Options = {
    // external
}

type GetAvailabilityResponse = {
    isAvailable: boolean;
}

type RequestDeviceRequest = {
    options: Options;
}

type RequestDeviceResponse = {
    uuid: string;
    name?: string;
}

export const getOrCreateDevice = (uuid: string, name?: string): BluetoothDevice => {
    const existing = store.getDevice(uuid);
    if (existing) {
        return existing;
    }
    const device = new BluetoothDevice(uuid, name);
    store.addDevice(device);
    return device;
}

// https://developer.mozilla.org/en-US/docs/Web/API/Bluetooth
export class Bluetooth extends EventTarget {
    activeScans: BluetoothLEScan[] = [];

    constructor() {
        super();
        this.addEventListener('availabilitychanged', (event) => {
            this.onavailabilitychanged(event);
        });
    }

    // Alternative API to the availabilitychanged event listener
    // https://webdocs.dev/en-us/docs/web/api/bluetooth/availabilitychanged_event
    onavailabilitychanged = (event: ValueEvent<boolean>) => {
    };

    getAvailability = async (): Promise<boolean> => {
        const response = await bluetoothRequest<undefined, GetAvailabilityResponse>(
            'getAvailability'
        );
        return response.isAvailable;
    }

    getDevices = async (): Promise<BluetoothDevice[]> => {
        const response = await bluetoothRequest<undefined, RequestDeviceResponse[]>(
            'getDevices'
        );
        return response.map(device => getOrCreateDevice(device.uuid, device.name));
    }

    requestDevice = async (options?: Options): Promise<BluetoothDevice> => {
        const response = await bluetoothRequest<RequestDeviceRequest, RequestDeviceResponse>(
            'requestDevice',
            { options: options }
        );
        return getOrCreateDevice(response.uuid, response.name);
    }

    requestLEScan = async (options?: BluetoothLEScanOptions): Promise<BluetoothLEScan> => {
        return doRequestLEScan(options);
    }
}
