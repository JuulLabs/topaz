// Polyfill for https://developer.mozilla.org/en-US/docs/Web/API/Bluetooth

import { Topaz } from "./Topaz";

if (typeof((navigator as any).bluetooth) === 'undefined') {
    globalThis.topaz = new Topaz();
    (navigator as any).bluetooth = globalThis.topaz.bluetooth;
}
