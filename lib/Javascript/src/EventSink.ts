import { convertToAdvertisingEvent } from "./BluetoothAdvertisingEvent";
import { base64ToDataView } from "./Data";
import { store } from "./Store";
import { ValueEvent } from "./ValueEvent";

export type TargetedEvent = {
    id: string;
    name: string;
    data?: any;
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
        eventToSend = convertToAdvertisingEvent(event);
    }

    if (!eventToSend) {
        // The default is a ValueEvent with the raw data payload
        eventToSend = new ValueEvent(event.name, { value: event.data });
    }

    for (const target of targets) {
        target.dispatchEvent(eventToSend);
    }
}
