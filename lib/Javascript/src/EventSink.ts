import { mainDispatcher } from "./EventDispatcher";
import { ValueEvent } from "./ValueEvent";

export type TargetedEvent = {
    id: string;
    name: string;
    data?: any;
}

export function dispatchEvent(event: TargetedEvent) {
    // TODO: find out if we need to support other event types
    const valueEvent = new ValueEvent(event.name, { value: event.data });
    mainDispatcher.postMessage(event.id, valueEvent);
}
