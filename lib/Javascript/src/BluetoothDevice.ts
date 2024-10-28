import { BluetoothRemoteGATTServer } from "./BluetoothRemoteGATTServer";
import { mainDispatcher } from "./EventDispatcher";

// https://developer.mozilla.org/en-US/docs/Web/API/BluetoothDevice
export class BluetoothDevice extends EventTarget {
    uuid: string;
    name: string | undefined;
    gatt: BluetoothRemoteGATTServer;

    constructor(uuid: string, name?: string) {
        super();
        this.uuid = uuid;
        this.name = name;
        this.gatt = new BluetoothRemoteGATTServer(this);

        mainDispatcher.addTarget(uuid, "gattserverdisconnected", this);
    }

    // TODO:
}
