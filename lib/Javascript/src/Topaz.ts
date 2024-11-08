import { Bluetooth } from "./Bluetooth";
import { base64ToDataView } from "./Data";
import { dispatchEvent, TargetedEvent } from "./EventSink";
import { store } from "./Store";

export class Topaz {
    bluetooth: Bluetooth;

    constructor() {
        this.bluetooth = new Bluetooth();
    }

    sendEvent = (event: TargetedEvent) => {
        if (event.name === 'characteristicvaluechanged') {
            const data = base64ToDataView(event.data);
            store.updateCharacteristicValue(event.id, data);
        }
        dispatchEvent(event);
    }
}
