import { BluetoothRemoteGATTServer } from "./BluetoothRemoteGATTServer";

// https://developer.mozilla.org/en-US/docs/Web/API/BluetoothDevice
export class BluetoothDevice extends EventTarget {
    id: string;
    name: string | undefined;
    gatt: BluetoothRemoteGATTServer;

    constructor(id: string, name?: string) {
        super();
        this.id = id;
        this.name = name;
        this.gatt = new BluetoothRemoteGATTServer(this);
    }

    // TODO:
}
