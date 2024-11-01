import { BluetoothDevice } from "./BluetoothDevice";
import { bluetoothRequest } from "./WebKit";
import { BluetoothRemoteGATTService } from "./BluetoothRemoteGATTService";

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

type GetPrimaryServicesRequest = {
    uuid: string;
    bluetoothServiceUUID?: string;
}

type GetPrimaryServicesResponse = {
    services: string[];
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

    // https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTServer/getPrimaryServices
    getPrimaryServices = async (bluetoothServiceUUID?: string): Promise<Array<BluetoothRemoteGATTService>> => {
        const response = await bluetoothRequest<GetPrimaryServicesRequest, GetPrimaryServicesResponse>(
            'getPrimaryServices',
            {
                uuid: this.device.uuid,
                bluetoothServiceUUID: bluetoothServiceUUID
            }
        );
        return response.services.map(service => new BluetoothRemoteGATTService(this.device, service, true));
    }

    // TODO:
}
