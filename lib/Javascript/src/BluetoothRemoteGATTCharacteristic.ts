import { BluetoothRemoteGATTService } from "./BluetoothRemoteGATTService";
import { BluetoothCharacteristicProperties } from "./BluetoothCharacteristicProperties";

// https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTCharacteristic
export class BluetoothRemoteGATTCharacteristic extends EventTarget {
    public value?: DataView;

    constructor(
        public service: BluetoothRemoteGATTService,
        public uuid: string,
        public properties: BluetoothCharacteristicProperties,
        private instanceId: number
    ) {
        super();
        this.value = null;
    }

    // TODO:
}
