import { Bluetooth } from "./Bluetooth";
import { processEvent, TargetedEvent } from "./EventSink";

export class Topaz {
    bluetooth: Bluetooth;

    constructor() {
        this.bluetooth = new Bluetooth();
    }

    sendEvent = (event: TargetedEvent) => {
        processEvent(event);
    }
}
