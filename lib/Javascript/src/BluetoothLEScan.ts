// https://webbluetoothcg.github.io/web-bluetooth/#device-discovery

import { Bluetooth } from "./Bluetooth";
import { bluetoothRequest } from "./WebKit";

export type BluetoothLEScanFilter = {
    // NOTE: Taking a shortcut here, rather than define all of the types we just pass through the input.
    // This is technically incorrect and we should define the types because the specification requires that
    // the `BluetoothLEScanFilterInit` objects be used to conjure the `BluetoothLEScanFilter` objects.
    // These things just get parked on the `BluetoothLEScan` object for reference, and as they are derived
    // from the original input it is hard to imagine what the use case it for this so lets not do it for now.
    // If we do end up defining the types, we should also update the `RequestDeviceOptions`.
}

export type BluetoothLEScanOptions = {
    keepRepeatedDevices: boolean;
    acceptAllAdvertisements: boolean;
    filters: BluetoothLEScanFilter[];
}

type RequestLEScanRequest = {
    scanId?: string;
    stop?: boolean;
    options?: BluetoothLEScanOptions;
}

type RequestLEScanResponse = {
    scanId: string;
    active: boolean;
    acceptAllAdvertisements: boolean;
    keepRepeatedDevices: boolean;
}

const addToActiveScans = (scan: BluetoothLEScan) => {
    const bluetooth: Bluetooth = globalThis.topaz.bluetooth;
    removeFromActiveScans(scan.scanId);
    bluetooth.activeScans.push(scan);
}

const removeFromActiveScans = (scanId: string) => {
    const bluetooth: Bluetooth = globalThis.topaz.bluetooth;
    bluetooth.activeScans = bluetooth.activeScans.filter((s) => s.scanId !== scanId);
}

// https://webbluetoothcg.github.io/web-bluetooth/scanning.html#bluetoothlescan
export class BluetoothLEScan {

    constructor(
        public scanId: string,
        public filters: BluetoothLEScanFilter[],
        public keepRepeatedDevices: boolean,
        public acceptAllAdvertisements: boolean,
        public active: boolean
    ) {
    }

    stop = () => {
        this.active = false;
        removeFromActiveScans(this.scanId);
        bluetoothRequest<RequestLEScanRequest, RequestLEScanResponse>(
            'requestLEScan',
            { scanId: this.scanId, stop: true }
        );
    }
}

// https://webbluetoothcg.github.io/web-bluetooth/scanning.html#scanning
export const doRequestLEScan = async (options?: BluetoothLEScanOptions): Promise<BluetoothLEScan> => {
    const response = await bluetoothRequest<RequestLEScanRequest, RequestLEScanResponse>(
        'requestLEScan',
        { options: options }
    );
    const newScan = new BluetoothLEScan(
        response.scanId,
        options.filters, // Note: Passing through the input filters as a shortcut here
        response.keepRepeatedDevices,
        response.acceptAllAdvertisements,
        response.active
    );
    addToActiveScans(newScan);
    return newScan;
}
