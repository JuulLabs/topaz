// https://webbluetoothcg.github.io/web-bluetooth/#device-discovery

import { BluetoothUUID } from "./BluetoothUUID";
import { EmptyObject } from "./EmptyObject";
import { bluetoothRequest } from "./WebKit";

// export type BluetoothServiceUUID = string | number;

// export interface BluetoothDataFilterInit {
//     dataPrefix?: ArrayBuffer;
// 	mask?: ArrayBuffer;
// }

// export class BluetoothDataFilter {
//     dataPrefix: ArrayBuffer;
//     mask: ArrayBuffer;

//     constructor(
//         init: BluetoothDataFilterInit = {}
//     ) {
//         this.dataPrefix = init.dataPrefix ? new Uint8Array(init.dataPrefix.slice(0)) : new ArrayBuffer(0);
//         this.mask = init.mask ? new Uint8Array(init.mask.slice(0)) : new ArrayBuffer(0);
//     }
// }

// export interface BluetoothManufacturerDataFilterInit extends BluetoothDataFilterInit {
//     companyIdentifier: BluetoothServiceUUID;
// }

// export interface BluetoothServiceDataFilterInit extends BluetoothDataFilterInit {
//     service: BluetoothServiceUUID;
// }

// export class BluetoothManufacturerDataFilter extends Map<BluetoothServiceUUID, BluetoothDataFilter> {
    
//     // companyIdentifier: BluetoothServiceUUID;

//     constructor(
//         init: BluetoothManufacturerDataFilterInit
//     ) {
//         super();
//         this.set(init.companyIdentifier, new BluetoothDataFilter(init));
//     }
// }

// export class BluetoothServiceDataFilter {
// }

// export interface BluetoothLEScanFilterInit {
//     services?: Array<BluetoothServiceUUID>;
//     name?: string;
//     namePrefix?: string;
//     manufacturerData?: Array<BluetoothManufacturerDataFilterInit>;
//     serviceData?: Array<BluetoothServiceDataFilterInit>;
// }

// export class BluetoothLEScanFilter {
//     // constructor(optional BluetoothLEScanFilterInit init = {});
//     // readonly attribute DOMString? name;
//     // readonly attribute DOMString? namePrefix;
//     // readonly attribute FrozenArray<UUID> services;
//     // readonly attribute BluetoothManufacturerDataFilter manufacturerData;
//     // readonly attribute BluetoothServiceDataFilter serviceData;
    
//     name?: string;
//     namePrefix?: string;
//     services?: Array<BluetoothServiceUUID>;
//     manufacturerData: BluetoothManufacturerDataFilter;
//     serviceData: BluetoothServiceDataFilter;

//     constructor(
//         init: BluetoothLEScanFilterInit = {}
//     ) {
//         this.name = init.name;
//         this.namePrefix = init.namePrefix;
//         this.services = init.services?.map((service) => BluetoothUUID.getService(service)) ?? [];
//     }
// }

type BluetoothLEScanFilter = {
    // external
}

export type BluetoothLEScanOptions = {
    // external
}

type RequestLEScanResponse = {
    scanId: string;
}

type ScanStopRequest = {
    scanId: string;
    stop: boolean;
}

// https://webbluetoothcg.github.io/web-bluetooth/scanning.html#bluetoothlescan
export class BluetoothLEScan {

    constructor(
        private id: string,
        public filters: BluetoothLEScanFilter[],
        public keepRepeatedDevices: boolean,
        public acceptAllAdvertisements: boolean,
        public active: boolean
    ) {
    }

    stop = () => {
        bluetoothRequest<ScanStopRequest, EmptyObject>(
            'requestLEScan',
            { scanId: this.id, stop: true }
        );
    }
}

// https://webbluetoothcg.github.io/web-bluetooth/scanning.html#scanning
export const doRequestLEScan = async (options?: BluetoothLEScanOptions): Promise<BluetoothLEScan> => {
    const response = await bluetoothRequest<BluetoothLEScanOptions, RequestLEScanResponse>(
        'requestLEScan',
        { options: options }
    );
    // TODO: convert request to Js BluetoothLEScan response
    // Attach the scan object to the object graph for later reference
    // when stopped, find the reference and flip the active flag to false and discard
    return new BluetoothLEScan(response.scanId, [], false, false, true);
}
