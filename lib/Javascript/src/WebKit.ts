
export interface WebKitMessage {
  action: string;
  data?: any;
}

declare namespace window.webkit.messageHandlers.bluetooth {
    function postMessage<T>(message: WebKitMessage): Promise<T>;
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
