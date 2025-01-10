import { BluetoothCharacteristicProperties } from "./BluetoothCharacteristicProperties";
import { BluetoothRemoteGATTService } from "./BluetoothRemoteGATTService";
import { bluetoothRequest } from "./WebKit";

type CharacteristicRequest = {
    device: string;
    service: string;
    characteristic: string;
    instance: number;
}

// https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTCharacteristic
export class BluetoothRemoteGATTCharacteristic extends EventTarget {
    // https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTCharacteristic/value
    public value?: DataView;

    constructor(
        public service: BluetoothRemoteGATTService,
        public uuid: string,
        public properties: BluetoothCharacteristicProperties,
        public instance: number
    ) {
        super();
        this.value = null;
    }

    // https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTCharacteristic/readValue
    readValue = async (): Promise<DataView> => {
        await bluetoothRequest<CharacteristicRequest, void>(
            'readCharacteristic',
            {
                device: this.service.device.uuid,
                service: this.service.uuid,
                characteristic: this.uuid,
                instance: this.instance
            }
        )
        return copyOf(this.value)
    }

    startNotifications = async (): Promise<BluetoothRemoteGATTCharacteristic> => {
        await bluetoothRequest<CharacteristicRequest, void>(
            'startNotifications',
            {
                device: this.service.device.uuid,
                service: this.service.uuid,
                characteristic: this.uuid,
                instance: this.instance
            }
        )
        return this
    }

    stopNotifications = async (): Promise<BluetoothRemoteGATTCharacteristic> => {
        await bluetoothRequest<CharacteristicRequest, void>(
            'stopNotifications',
            {
                device: this.service.device.uuid,
                service: this.service.uuid,
                characteristic: this.uuid,
                instance: this.instance
            }
        )
        return this
    }
}

function copyOf(data: DataView): DataView {
    return new DataView(data.buffer.slice(0))
}
