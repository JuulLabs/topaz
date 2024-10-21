import { eventSinkRequest } from "./WebKit";
import { mainDispatcher } from "./EventDispatcher";
import { ValueEvent } from "./ValueEvent";

async function collectAndDispatch() {
    const events = await eventSinkRequest();
    events.forEach((event) => {
        // TODO: find out if we need to support other event types
        const valueEvent = new ValueEvent(event.name, { value: event.data });
        mainDispatcher.postMessage(event.id, valueEvent);
    });
}

export async function drainEvents() {
    while (true) {
        await collectAndDispatch();
    }
}
