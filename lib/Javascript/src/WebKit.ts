import { rethrowAsDOMException } from "./Error";

// Channels map one-to-one to the available WebKit JsMessageHandlers
declare namespace window.webkit.messageHandlers {
    const bluetooth: Channel<BluetoothMessage>;
    const logging: Channel<LogMessage>;
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
    }).catch(rethrowAsDOMException);
}


// Logging Channel

export type LogMessage = {
    level?: string;
    msg: string;
    console?: boolean;
    sensitive?: boolean;
    data?: any;
}

export const appLog = function (msg: LogMessage): Promise<void> {
    return window.webkit.messageHandlers.logging.postMessage<void>(msg).catch(rethrowAsDOMException);
}
