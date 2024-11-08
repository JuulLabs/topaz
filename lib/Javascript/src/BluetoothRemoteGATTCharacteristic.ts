import { BluetoothRemoteGATTService } from "./BluetoothRemoteGATTService";
import { BluetoothCharacteristicProperties } from "./BluetoothCharacteristicProperties";

// https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTCharacteristic
export class BluetoothRemoteGATTCharacteristic extends EventTarget {
    #instance: number;
    public value?: DataView;

    constructor(
        public service: BluetoothRemoteGATTService,
        public uuid: string,
        public properties: BluetoothCharacteristicProperties,
        instance: number
    ) {
        super();
        this.#instance = instance;
        this.value = null;
    }

    // TODO:
}
