import { base64ToDataView } from "./Data";
import { Bluetooth } from "./Bluetooth";
import { dispatchEvent, TargetedEvent } from "./EventSink";
import { mainDispatcher } from "./EventDispatcher";
import { store } from "./Store";
import { ValueEvent } from "./ValueEvent";

export class Topaz {
    bluetooth: Bluetooth;

    constructor() {
        this.bluetooth = new Bluetooth();
    }

    sendEvent = (event: TargetedEvent) => {
        if (event.name === 'characteristicvaluechanged') {
            const data = base64ToDataView(event.data);
            store.updateCharacteristicValue(event.id, data);
            const valueEvent = new ValueEvent(event.name, { value: data });
            mainDispatcher.postMessage(event.id, valueEvent);
        } else {
            dispatchEvent(event);
        }
    }
}
