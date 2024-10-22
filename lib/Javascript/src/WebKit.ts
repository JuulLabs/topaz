
type BluetoothMessage = {
  action: string;
  data?: any;
}

declare namespace window.webkit.messageHandlers.bluetooth {
    function postMessage<T>(message: BluetoothMessage): Promise<T>;
}

export const bluetoothRequest = function <Request, Response>(
  action: string,
  data?: Request,
): Promise<Response> {
  return window.webkit.messageHandlers.bluetooth.postMessage({
    action: action,
    data: data
  });
}


type TargetedEvent = {
    id: string;
    name: string;
    data?: any;
}

// To trigger WebKit we have to send a non-null value - empty object is fine
type EventSinkMessage = {
}

declare namespace window.webkit.messageHandlers.eventsink {
    function postMessage<T>(message: EventSinkMessage): Promise<T>;
}

export const eventSinkRequest = function (): Promise<TargetedEvent[]> {
  return window.webkit.messageHandlers.eventsink.postMessage({});
}
