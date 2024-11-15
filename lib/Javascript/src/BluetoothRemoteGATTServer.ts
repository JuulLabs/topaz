import { BluetoothDevice } from "./BluetoothDevice";
import { bluetoothRequest } from "./WebKit";
import { BluetoothRemoteGATTService } from "./BluetoothRemoteGATTService";
import { store } from "./Store";
import { BluetoothUUID } from "./BluetoothUUID";

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
    device: string;
    service: string;
    single: boolean;
}

type DiscoverServicesResponse = {
    services: string[];
}

const getOrCreateService = (device: BluetoothDevice, uuid: string, isPrimary: boolean): BluetoothRemoteGATTService => {
    const existingService = store.getService(device.uuid, uuid);
    if (existingService) {
        return existingService;
    }
    const service = new BluetoothRemoteGATTService(device, uuid, isPrimary);
    store.addService(service);
    return service;
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
    private GetGATTChildren = async (single: boolean, service?: string | number): Promise<Array<BluetoothRemoteGATTService>> => {
        const response = await bluetoothRequest<DiscoverServicesRequest, DiscoverServicesResponse>(
            'discoverServices',
            {
                device: this.device.uuid,
                service: service ? BluetoothUUID.getService(service) : null,
                single: single
            }
        );
        return response.services.map(service => getOrCreateService(this.device, service, true));
    }

    // https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTServer/getPrimaryService
    getPrimaryService = async (bluetoothServiceUUID?: string | number): Promise<BluetoothRemoteGATTService> => {
        if (typeof bluetoothServiceUUID === "undefined") {
            throw new TypeError("Missing 'bluetoothServiceUUID' parameter.")
        }
        const services = await this.GetGATTChildren(true, bluetoothServiceUUID)
        return services[0]
    }

    // https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTServer/getPrimaryServices
    getPrimaryServices = async (bluetoothServiceUUID?: string): Promise<BluetoothRemoteGATTService[]> => {
        return this.GetGATTChildren(false, bluetoothServiceUUID)
    }

    // TODO:
}
