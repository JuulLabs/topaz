import { createDevice } from "./Bluetooth";
import { BluetoothAdvertisingEvent } from "./BluetoothAdvertisingEvent";
import { base64ToDataView } from "./Data";
import { store } from "./Store";
import { ValueEvent } from "./ValueEvent";
import { appLog } from "./WebKit";

export type TargetedEvent = {
    id: string;
    name: string;
    data?: any;
}

type AdvertisementEvent = {
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

export const processEvent = (event: TargetedEvent) => {
    let eventToSend: Event;
    let targets: EventTarget[] = [];

    if (event.id === 'bluetooth') {
        // This is the magic ID for the global Bluetooth object
        targets.push(globalThis.topaz.bluetooth);
    }
    
    if (event.name === 'gattserverdisconnected') {
        // Forward this to the specific device
        const device = store.getDevice(event.id);
        if (device) {
            targets.push(device);
        }
    } else if (event.name === 'characteristicvaluechanged') {
        // Decode the data payload, update the store, and forward event to the specific characteristic
        const data = base64ToDataView(event.data);
        const characteristic = store.updateCharacteristicValue(event.id, data);
        targets.push(characteristic);
        eventToSend = new ValueEvent(event.name, { value: data });
    } else if (event.name === 'advertisementreceived') {
        const adEvent: AdvertisementEvent = event.data;
        let device = store.getDevice(adEvent.device.uuid);
        if (!device) {
            device = createDevice(adEvent.device.uuid, adEvent.device.name);
        }
        let manufacturerData = new Map<number, DataView>();
        if (adEvent.advertisement.manufacturerData) {
            manufacturerData.set(adEvent.advertisement.manufacturerData.code, base64ToDataView(adEvent.advertisement.manufacturerData.data));
        };
        let serviceData = new Map<string, DataView>();
        for (const [key, value] of Object.entries(adEvent.advertisement.serviceData)) {
            serviceData.set(key, base64ToDataView(value));
        };
        eventToSend = new BluetoothAdvertisingEvent(event.name, {
            device: device,
            uuids: adEvent.advertisement.uuids,
            name: adEvent.advertisement.name,
            rssi: adEvent.advertisement.rssi,
            txPower: adEvent.advertisement.txPower,
            manufacturerData: manufacturerData,
            serviceData: serviceData,
        });
    }

    if (!eventToSend) {
        // The default is a ValueEvent with the raw data payload
        eventToSend = new ValueEvent(event.name, { value: event.data });
    }

    for (const target of targets) {
        target.dispatchEvent(eventToSend);
    }
}
