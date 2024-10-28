import { BluetoothDevice } from "./BluetoothDevice";
import { bluetoothRequest } from "./WebKit";

type ConnectRequest = {
    uuid: string;
}

type ConnectResponse = {
    connected: boolean;
}

type DisconnectRequest = {
    uuid: string;
}

type DisconnectResponse = {
    disconnected: boolean;
}

// https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTServer
export class BluetoothRemoteGATTServer {
    device: BluetoothDevice;
    connected: boolean;

    constructor(device: BluetoothDevice) {
        this.device = device;
        this.connected = false;
    }

    connect = async (): Promise<BluetoothRemoteGATTServer> => {
        const response = await bluetoothRequest<ConnectRequest, ConnectResponse>(
            'connect',
            { uuid: this.device.uuid }
        );
        this.connected = response.connected;
        return this;
    }

    disconnect = async (): Promise<void> => {
        const response = await bluetoothRequest<DisconnectRequest, DisconnectResponse>(
            'disconnect',
            { uuid: this.device.uuid }
        );
        this.connected = !response.disconnected;
    }

    // TODO:
}
