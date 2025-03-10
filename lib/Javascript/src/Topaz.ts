import { Bluetooth } from "./Bluetooth";
import { processEvent, TargetedEvent } from "./EventSink";
import { appLog, LogMessage } from "./WebKit";

export class Topaz {
    bluetooth: Bluetooth;

    constructor() {
        this.bluetooth = new Bluetooth();
    }

    sendEvent = (event: TargetedEvent) => {
        processEvent(event);
    }
}
