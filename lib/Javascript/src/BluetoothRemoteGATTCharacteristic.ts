import { bluetoothRequest } from "./WebKit";
import { BluetoothRemoteGATTService } from "./BluetoothRemoteGATTService";
import { BluetoothCharacteristicProperties } from "./BluetoothCharacteristicProperties";

type ReadCharacteristicRequest = {
    device: string;
    service: string;
    characteristic: string;
    instance: number;
}

// https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTCharacteristic
export class BluetoothRemoteGATTCharacteristic extends EventTarget {
    #instance: number;

    // https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTCharacteristic/value
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

    // https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTCharacteristic/readValue
    readValue = async (): Promise<DataView> => {
        await bluetoothRequest<ReadCharacteristicRequest, void>(
            'readCharacteristic',
            {
                device: this.service.device.uuid,
                service: this.service.uuid,
                characteristic: this.uuid,
                instance: this.#instance
            }
        )
        return copyOf(this.value)
    }
}

function copyOf(data: DataView): DataView {
    return new DataView(data.buffer.slice(0))
}
