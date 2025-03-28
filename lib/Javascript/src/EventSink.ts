import { convertToAdvertisingEvent } from "./BluetoothAdvertisingEvent";
import { convertToCharacteristicEvent } from "./CharacteristicValueChangedEvent";
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

    const pushDeviceTarget = () => {
        if (event.id !== 'bluetooth') {
            const device = store.getDevice(event.id);
            if (device) {
                targets.push(device);
            }
        }
    }

    if (event.name === 'gattserverdisconnected') {
        pushDeviceTarget();
    } else if (event.name === 'characteristicvaluechanged') {
        // Decode the data payload, update the store, and forward event to the specific characteristic
        const characteristicEvent = convertToCharacteristicEvent(event);
        targets.push(characteristicEvent.characteristic);
        eventToSend = characteristicEvent.event;
    } else if (event.name === 'advertisementreceived') {
        eventToSend = convertToAdvertisingEvent(event);
        pushDeviceTarget();
    }

    if (!eventToSend) {
        // The default is a ValueEvent with the raw data payload
        eventToSend = new ValueEvent(event.name, { value: event.data });
    }

    for (const target of targets) {
        target.dispatchEvent(eventToSend);
        // Invoke the on<event> handler if it exists
        const handler = target['on' + eventToSend.type];
        if (handler) {
            handler(eventToSend);
        }
    }
}
