import { BluetoothRemoteGATTServer } from "./BluetoothRemoteGATTServer";
import { EmptyObject } from "./EmptyObject";
import { store } from "./Store";
import { bluetoothRequest } from "./WebKit";

type ForgetDeviceRequest = {
    uuid: string;
}

type ForgetDeviceResponse = EmptyObject;

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

    forget = async (): Promise<void> => {
        await bluetoothRequest<ForgetDeviceRequest, ForgetDeviceResponse>(
            'forgetDevice',
            { uuid: this.id }
        );
        store.removeDevice(this.id);
        return;
    }
}
