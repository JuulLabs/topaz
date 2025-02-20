import { arrayBufferToBase64 } from "./Data";
import { base64ToDataView } from "./Data";
import { BluetoothRemoteGATTCharacteristic } from "./BluetoothRemoteGATTCharacteristic";
import { bluetoothRequest } from "./WebKit";
import { copyOf } from "./Data";
import { EmptyObject } from "./EmptyObject";
import { isView } from "./Data";

type ReadDescriptorRequest = {
    device: string;
    service: string;
    characteristic: string;
    instance: number;
    descriptor: string;
}

type WriteDescriptorRequest = {
    device: string;
    service: string;
    characteristic: string;
    instance: number;
    descriptor: string,
    value: string;
}

// https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTDescriptor
export class BluetoothRemoteGATTDescriptor {
    // https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTDescriptor/value
    public value?: DataView;

    constructor(
        public characteristic: BluetoothRemoteGATTCharacteristic,
        public uuid: string
    ) {
        this.value = null;
    }

    // https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTCharacteristic/readValue
    readValue = async (): Promise<DataView> => {
        const response = await bluetoothRequest<ReadDescriptorRequest, string>(
            'readDescriptor',
            {
                device: this.characteristic.service.device.id,
                service: this.characteristic.service.uuid,
                characteristic: this.characteristic.uuid,
                instance: this.characteristic.instance,
                descriptor: this.uuid
            }
        )
        this.value = base64ToDataView(response)
        return copyOf(this.value)
    }
    
    writeValue = async (value: ArrayBuffer | ArrayBufferView): Promise<void> => {
        const arrayBuffer = isView(value) ? value.buffer : value;
        const base64 = arrayBufferToBase64(arrayBuffer)
        await bluetoothRequest<WriteDescriptorRequest, EmptyObject>(
            'writeDescriptor',
            {
                device: this.characteristic.service.device.id,
                service: this.characteristic.service.uuid,
                characteristic: this.characteristic.uuid,
                instance: this.characteristic.instance,
                descriptor: this.uuid,
                value: base64
            }
        )
    }
}
