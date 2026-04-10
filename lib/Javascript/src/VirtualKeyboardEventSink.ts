import { EventDispatch, TargetedEvent } from "./EventSink";

export const processVirtualKeyboardEvent = (event: TargetedEvent): EventDispatch => {
    let eventToSend: Event;
    let targets: EventTarget[] = [];

    if (event.id === 'keyboard' && event.name === 'geometrychange') {
        globalThis.topaz.virtualKeyboard._updateBoundingRect(event.data);
        targets.push(globalThis.topaz.virtualKeyboard);
        eventToSend = new Event(event.name);
    }

    return { event: eventToSend, targets: targets };
}
