import { BluetoothRemoteGATTCharacteristic } from "./BluetoothRemoteGATTCharacteristic";
import { base64ToDataView } from "./Data";
import type { TargetedEvent } from "./EventSink";
import { store } from "./Store";
import { ValueEvent } from "./ValueEvent";

export type CharacteristicEvent = {
    characteristic: BluetoothRemoteGATTCharacteristic;
    event: ValueEvent<DataView>;
}

// The payload as defined in the Swift code CharacteristicResponse:
type CharacteristicEventPayload = {
    device: string;
    service: string;
    characteristic: string;
    instance: number;
    value: string;
}

// Assumes event.name === 'characteristicvaluechanged'
// Side effect: updates the value property of the characteristic in the store
export const convertToCharacteristicEvent = (event: TargetedEvent): CharacteristicEvent => {
    const payload: CharacteristicEventPayload = event.data;
    const data = base64ToDataView(payload.value);
    const characteristic = store.updateCharacteristicValue(payload.device, payload.service, payload.characteristic, payload.instance, data);
    return { characteristic, event: new ValueEvent(event.name, { value: data }) };
}
