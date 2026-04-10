import { convertToAdvertisingEvent } from "./BluetoothAdvertisingEvent";
import { convertToCharacteristicEvent } from "./CharacteristicValueChangedEvent";
import { EventDispatch, TargetedEvent } from "./EventSink";
import { store } from "./Store";
import { ValueEvent } from "./ValueEvent";

export const processBluetoothEvent = (event: TargetedEvent): EventDispatch => {
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

    return { event: eventToSend, targets: targets };
}
