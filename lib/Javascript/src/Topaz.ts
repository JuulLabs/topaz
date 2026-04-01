import { Bluetooth } from "./Bluetooth";
import { processEvent, TargetedEvent } from "./EventSink";
import { setupLogging } from "./Logging";
import { VirtualKeyboard } from "./VirtualKeyboard";

export class Topaz {
    bluetooth: Bluetooth;
    virtualKeyboard: VirtualKeyboard;

    constructor() {
        this.bluetooth = new Bluetooth();
        this.virtualKeyboard = new VirtualKeyboard();
    }

    sendEvent = (event: TargetedEvent) => {
        processEvent(event);
    }
}

export const ensureInitialized = () => {
    if (globalThis.topaz === undefined) {
        globalThis.topaz = new Topaz();
        setupLogging();
    }
}
