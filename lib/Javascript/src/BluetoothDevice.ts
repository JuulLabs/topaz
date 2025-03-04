import { BluetoothRemoteGATTServer } from "./BluetoothRemoteGATTServer";
import { EmptyObject } from "./EmptyObject";
import { store } from "./Store";
import { bluetoothRequest } from "./WebKit";

type ForgetDeviceRequest = {
    uuid: string;
}

type ForgetDeviceResponse = EmptyObject;

type WatchAdvertisementsRequest = {
    uuid: string;
    enable: boolean;
}

type WatchAdvertisementsResponse = EmptyObject;

type WatchAdvertisementsOptions = {
    signal?: AbortSignal;
}

// https://developer.mozilla.org/en-US/docs/Web/API/BluetoothDevice
export class BluetoothDevice extends EventTarget {
    id: string;
    name: string | undefined;
    gatt: BluetoothRemoteGATTServer;
    watchingAdvertisements: boolean;

    constructor(id: string, name?: string) {
        super();
        this.id = id;
        this.name = name;
        this.gatt = new BluetoothRemoteGATTServer(this);
        this.watchingAdvertisements = false;
    }

    // TODO: https://html.spec.whatwg.org/multipage/webappapis.html#event-handler-idl-attributes
    // Events:
    // advertisementreceived
    // gattserverdisconnected
    // characteristicvaluechanged
    // serviceadded
    // servicechanged
    // serviceremoved

    forget = async (): Promise<void> => {
        await bluetoothRequest<ForgetDeviceRequest, ForgetDeviceResponse>(
            'forgetDevice',
            { uuid: this.id }
        );
        store.removeDevice(this.id);
    }

    watchAdvertisements = async (options?: WatchAdvertisementsOptions): Promise<void> => {
        let signal = options?.signal;
        if (signal) {
            if (signal.aborted) {
                await this._toggleWatchingAdvertisements(false);
                return;
            }
            signal.addEventListener('abort', () => {
                this._toggleWatchingAdvertisements(false);
            });
        }
        if (!this.watchingAdvertisements) {
            await this._toggleWatchingAdvertisements(true);
        }
    }

    _toggleWatchingAdvertisements = async (isWatching: boolean): Promise<void> => {
        await bluetoothRequest<WatchAdvertisementsRequest, WatchAdvertisementsResponse>(
            'watchAdvertisements',
            { uuid: this.id, enable: isWatching }
        );
        this.watchingAdvertisements = isWatching;
    }
}
