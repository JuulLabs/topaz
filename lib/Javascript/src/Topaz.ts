import { Bluetooth } from "./Bluetooth";
import { sendEvent, TargetedEvent } from "./EventSink";

export class Topaz {
    bluetooth: Bluetooth;

    constructor() {
        this.bluetooth = new Bluetooth();
    }

    sendEvent = (event: TargetedEvent) => {
        sendEvent(event);
    }
}
