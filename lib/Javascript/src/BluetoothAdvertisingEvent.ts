// https://webbluetoothcg.github.io/web-bluetooth/#advertising-events

import { createDevice } from "./Bluetooth";
import { BluetoothDevice } from "./BluetoothDevice";
import { base64ToDataView } from "./Data";
import type { TargetedEvent } from "./EventSink";
import { store } from "./Store";

export interface BluetoothAdvertisingEventInit extends EventInit {
    device: BluetoothDevice;
    uuids: (string | number)[];
    name?: string;
    appearance?: number;
    txPower?: number;
    rssi?: number;
    manufacturerData?: Map<number, DataView>;
    serviceData?: Map<string, DataView>;
};

export class BluetoothAdvertisingEvent extends Event {
    device: BluetoothDevice;
    uuids: (string | number)[];
    name?: string;
    appearance?: number;
    txPower?: number;
    rssi?: number;
    manufacturerData: Map<number, DataView>;
    serviceData: Map<string, DataView>;

    constructor(
        type: string,
        eventInitDict: BluetoothAdvertisingEventInit
    ) {
        super(type, eventInitDict);
        this.device = eventInitDict.device;
        this.uuids = eventInitDict.uuids;
        this.name = eventInitDict.name;
        this.appearance = eventInitDict.appearance;
        this.txPower = eventInitDict.txPower;
        this.rssi = eventInitDict.rssi;
        this.manufacturerData = eventInitDict.manufacturerData || new Map();
        this.serviceData = eventInitDict.serviceData || new Map();
    }
};

// The payload as defined in the Swift code RequestLEScanResponse:
type AdvertisementEventPayload = {
    advertisement: {
        uuids: string[];
        name: string;
        rssi: number;
        txPower: number;
        manufacturerData?: {
            code: number;
            data: string;
        };
        serviceData: {
            [key: string]: string;
        };
    };
    device: {
        uuid: string;
        name: string;
    };
}

// Assumes event.name === 'advertisementreceived'
// Side effect: creates a new device if it doesn't exist and adds it to the store
export const convertToAdvertisingEvent = (event: TargetedEvent): BluetoothAdvertisingEvent => {
    const payload: AdvertisementEventPayload = event.data;
    let device = store.getDevice(payload.device.uuid);
    if (!device) {
        device = createDevice(payload.device.uuid, payload.device.name);
    }
    let manufacturerData = new Map<number, DataView>();
    if (payload.advertisement.manufacturerData) {
        manufacturerData.set(
            payload.advertisement.manufacturerData.code,
            base64ToDataView(payload.advertisement.manufacturerData.data)
        );
    };
    let serviceData = new Map<string, DataView>();
    for (const [key, value] of Object.entries(payload.advertisement.serviceData)) {
        serviceData.set(key, base64ToDataView(value));
    };
    return new BluetoothAdvertisingEvent(event.name, {
        device: device,
        uuids: payload.advertisement.uuids,
        name: payload.advertisement.name,
        rssi: payload.advertisement.rssi,
        txPower: payload.advertisement.txPower,
        manufacturerData: manufacturerData,
        serviceData: serviceData,
    });
}
