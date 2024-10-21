import { BluetoothDevice } from "./BluetoothDevice";

// https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTService
export class BluetoothRemoteGATTService extends EventTarget {
    device: BluetoothDevice;
    uuid: string;
    isPrimary: boolean;

    constructor(device: BluetoothDevice, uuid: string, isPrimary: boolean) {
        super();
        this.device = device;
        this.uuid = uuid;
        this.isPrimary = isPrimary;
    }

    // TODO:
}
