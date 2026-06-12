import { Bluetooth } from "./Bluetooth";
import { processEvent, TargetedEvent } from "./EventSink";
import { setupLogging } from "./Logging";
import { VirtualKeyboard } from "./VirtualKeyboard";
import { topazRequest } from "./WebKit";

type UserAgentMode = "topaz" | "safari";

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

    setUserAgentMode = async (mode: UserAgentMode): Promise<void> => {
        await topazRequest<{ mode: UserAgentMode }, void>("setUserAgentMode", { mode });
    }
}

export const ensureInitialized = () => {
    if (globalThis.topaz === undefined) {
        globalThis.topaz = new Topaz();
        setupLogging();
    }
}
