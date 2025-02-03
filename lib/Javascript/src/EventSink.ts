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
        appLog('processEvent advertisementreceived ' + JSON.stringify(event));
        const adEvent: AdvertisementEvent = event.data;
        appLog('getDevice uuid=' + adEvent.device.uuid);
        let device = store.getDevice(adEvent.device.uuid);
        appLog('gotDevice ' + device);
        if (!device) {
            appLog('createDevice uuid=' + adEvent.device.uuid + ' name=' + adEvent.device.name);
            device = createDevice(adEvent.device.uuid, adEvent.device.name);
            appLog('did createDevice');
            // TODO: track these and throw them away when the scan ends
        }
        appLog('gotDevice x ' + device.id);
        eventToSend = new BluetoothAdvertisingEvent(event.name, {
            device: device,
            uuids: adEvent.advertisement.uuids,
            name: adEvent.advertisement.name,
            rssi: adEvent.advertisement.rssi,
            txPower: adEvent.advertisement.txPower,
            // TODO: manufacturerData and serviceData
        });
        appLog('send: ' + eventToSend);
    }

    if (!eventToSend) {
        // The default is a ValueEvent with the raw data payload
        eventToSend = new ValueEvent(event.name, { value: event.data });
    }

    for (const target of targets) {
        target.dispatchEvent(eventToSend);
    }
}
