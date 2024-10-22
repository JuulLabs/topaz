// Polyfill for https://developer.mozilla.org/en-US/docs/Web/API/Bluetooth

import { Bluetooth } from './Bluetooth';
import { drainEvents } from './EventSink';

if ((navigator as any).bluetooth === undefined) {
    (navigator as any).bluetooth = new Bluetooth();
    drainEvents();
}
