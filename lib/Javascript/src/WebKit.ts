import { rethrowAsDOMException } from "./Error";

// Channels map one-to-one to the available WebKit JsMessageHandlers
declare namespace window.webkit.messageHandlers {
    const bluetooth: Channel<BluetoothMessage>;
    const logging: Channel<LogMessage>;
    const nfc: Channel<NFCMessage>;
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

type LogMessage = {
    // TODO: log level
    msg: string;
}

export const appLog = function (msg: string): Promise<void> {
    return window.webkit.messageHandlers.logging.postMessage<void>({
        msg: msg
    }).catch(rethrowAsDOMException);
}


// NFC Channel

type NFCMessage = {
    action: string;
    data?: any;
  }
  
  export const nfcRequest = function <Request, Response>(
    action: string,
    data?: Request,
  ): Promise<Response> {
      return window.webkit.messageHandlers.nfc.postMessage<Response>({
          action: action,
          data: data
      }).catch(rethrowAsDOMException);
  }
  