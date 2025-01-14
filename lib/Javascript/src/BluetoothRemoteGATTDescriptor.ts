import { base64ToDataView } from "./Data";
import { BluetoothRemoteGATTCharacteristic } from "./BluetoothRemoteGATTCharacteristic";
import { bluetoothRequest } from "./WebKit";
import { copyOf } from "./Data";

type ReadDescriptorRequest = {
    device: string;
    service: string;
    characteristic: string;
    instance: number;
    descriptor: string;
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
                device: this.characteristic.service.device.uuid,
                service: this.characteristic.service.uuid,
                characteristic: this.characteristic.uuid,
                instance: this.characteristic.instance,
                descriptor: this.uuid
            }
        )
        this.value = base64ToDataView(response)
        return copyOf(this.value)
    }
}
