import { Bluetooth } from "./Bluetooth";
import { dispatchEvent, TargetedEvent } from "./EventSink";

export class Topaz {
    bluetooth: Bluetooth;

    constructor() {
        this.bluetooth = new Bluetooth();
    }

    sendEvent = (event: TargetedEvent) => {
        dispatchEvent(event);
    }
}
