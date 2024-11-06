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

type DiscoverServicesRequest = {
    uuid: string;
    single: boolean;
    service: string;
}

type DiscoverServicesResponse = {
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

    /**
     * Loosely models the `GetGATTChildren` function as described in the Web Bluetooth Specification:
     * https://webbluetoothcg.github.io/web-bluetooth/#bluetoothgattremoteserver-interface
     *
     * ```
     * Return GetGATTChildren(attribute=this.device,
     *                        single=<boolean>,
     *                        uuidCanonicalizer=BluetoothUUID.getService,
     *                        uuid=service,
     *                        allowedUuids=this.device.[[allowedServices]],
     *                        child type="GATT Primary Service")
     * ```
     */
    private GetGATTChildren = async (single: boolean, service?: string): Promise<Array<BluetoothRemoteGATTService>> => {
        const response = await bluetoothRequest<DiscoverServicesRequest, DiscoverServicesResponse>(
            'discoverServices',
            {
                uuid: this.device.uuid,
                single: single,
                service: service
            }
        );
        return response.services.map(service => new BluetoothRemoteGATTService(this.device, service, true));
    }

    // https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTServer/getPrimaryService
    getPrimaryService = async (bluetoothServiceUUID?: string): Promise<BluetoothRemoteGATTService> => {
        if (typeof bluetoothServiceUUID === "undefined") {
            throw new TypeError("Missing 'bluetoothServiceUUID' parameter.")
        }
        const services = await this.GetGATTChildren(true, bluetoothServiceUUID)
        return services[0]
    }

    // https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTServer/getPrimaryServices
    getPrimaryServices = async (bluetoothServiceUUID?: string): Promise<Array<BluetoothRemoteGATTService>> => {
        return this.GetGATTChildren(false, bluetoothServiceUUID)
    }

    // TODO:
}
