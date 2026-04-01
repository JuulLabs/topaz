import { processBluetoothEvent } from "./BluetoothEventSink";
import { processVirtualKeyboardEvent } from "./VirtualKeyboardEventSink";

export type TargetedEvent = {
    domain: string;
    id: string;
    name: string;
    data?: any;
}

export type EventDispatch = {
    event: Event;
    targets: EventTarget[];
}

export const processEvent = (event: TargetedEvent) => {
    let dispatch: EventDispatch;

    if (event.domain === 'keyboard') {
        dispatch = processVirtualKeyboardEvent(event);
    } else if (event.domain === 'bluetooth') {
        dispatch = processBluetoothEvent(event);
    }

    for (const target of dispatch.targets) {
        target.dispatchEvent(dispatch.event);
        // Invoke the on<event> handler if it exists
        const handler = target['on' + dispatch.event.type];
        if (handler) {
            handler(dispatch.event);
        }
    }
}
