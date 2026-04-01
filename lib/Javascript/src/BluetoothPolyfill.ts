// Polyfill for https://developer.mozilla.org/en-US/docs/Web/API/Bluetooth

import { ensureInitialized } from "./Topaz";
import { BluetoothUUID } from "./BluetoothUUID";

if (typeof((navigator as any).bluetooth) === 'undefined') {
    ensureInitialized();
    (navigator as any).bluetooth = globalThis.topaz.bluetooth;
}

if (typeof((window as any).BluetoothUUID) === 'undefined') {
    globalThis.BluetoothUUID = BluetoothUUID;
    (window as any).BluetoothUUID = globalThis.BluetoothUUID;
}

if (typeof((navigator as any).virtualKeyboard) === 'undefined') {
    ensureInitialized();
    (navigator as any).virtualKeyboard = globalThis.topaz.virtualKeyboard;
}
