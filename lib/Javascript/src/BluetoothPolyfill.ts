// Polyfill for https://developer.mozilla.org/en-US/docs/Web/API/Bluetooth

import { Topaz } from "./Topaz";
import { BluetoothUUID } from "./BluetoothUUID";
import { setupLogging } from "./Logging";

if (typeof((navigator as any).bluetooth) === 'undefined') {
    globalThis.topaz = new Topaz();
    (navigator as any).bluetooth = globalThis.topaz.bluetooth;
    setupLogging();
}

if (typeof((window as any).BluetoothUUID) === 'undefined') {
    globalThis.BluetoothUUID = BluetoothUUID;
    (window as any).BluetoothUUID = globalThis.BluetoothUUID;
}
