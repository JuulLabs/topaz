// Channels map one-to-one to the available WebKit JsMessageHandlers
declare namespace window.webkit.messageHandlers {
    const bluetooth: Channel<BluetoothMessage>;
}

interface Channel<Message> {
    postMessage<Reply>(message: Message): Promise<Reply>;
}


// Bluetooth Channel

type BluetoothMessage = {
  action: string;
  data?: any;
}

export const bluetoothRequest = function <Request, Response>(
  action: string,
  data?: Request,
): Promise<Response> {
    return window.webkit.messageHandlers.bluetooth.postMessage<Response>({
        action: action,
        data: data
    });
}
