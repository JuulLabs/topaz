// https://webbluetoothcg.github.io/web-bluetooth/#advertising-events

import { BluetoothDevice } from "./BluetoothDevice";

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
