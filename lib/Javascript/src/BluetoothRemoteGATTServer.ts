import { BluetoothDevice } from "./BluetoothDevice";
import { bluetoothRequest } from "./WebKit";

type ConnectRequest = {
    uuid: string;
}

type ConnectResponse = {
    connected: boolean;
}

// https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTServer
export class BluetoothRemoteGATTServer {
    device: BluetoothDevice;
    connected: boolean;

    constructor(device: BluetoothDevice) {
        this.device = device;
        this.connected = false;
    }

    connect = async function() {
        const response = await bluetoothRequest<ConnectRequest, ConnectResponse>(
            'connect',
            { uuid: this.device.id }
        );
        this.connected = response.connected;
        return this;
    }

    // TODO:
}
