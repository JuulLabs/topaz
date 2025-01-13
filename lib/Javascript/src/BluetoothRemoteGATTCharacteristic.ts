import { BluetoothCharacteristicProperties } from "./BluetoothCharacteristicProperties";
import { BluetoothRemoteGATTDescriptor } from "./BluetoothRemoteGATTDescriptor";
import { BluetoothRemoteGATTService } from "./BluetoothRemoteGATTService";
import { bluetoothRequest } from "./WebKit";
import { BluetoothUUID } from "./BluetoothUUID";
import { copyOf } from "./Data";
import { store } from "./Store";

type DiscoverDescriptorsRequest = {
    device: string;
    service: string;
    characteristic: string;
    instance: number;
    descriptor?: string;
    single: boolean;
}

type ReadCharacteristicRequest = {
    device: string;
    service: string;
    characteristic: string;
    instance: number;
}

const getOrCreateDescriptor = (
    characteristic: BluetoothRemoteGATTCharacteristic,
    uuid: string
): BluetoothRemoteGATTDescriptor => {
    const existingDescriptor = store.getDescriptor(characteristic, uuid);
    if (existingDescriptor) {
        return existingDescriptor;
    }
    const descriptor = new BluetoothRemoteGATTDescriptor(characteristic, uuid);
    store.addDescriptor(characteristic, descriptor);
    return descriptor;
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

    /**
     * Loosely models the `GetGATTChildren` function as described in the Web Bluetooth Specification:
     * https://webbluetoothcg.github.io/web-bluetooth/#bluetoothgattcharacteristic-interface
     *
     * ```
     * Return GetGATTChildren(attribute=this,
     *                        single=<boolean>,
     *                        uuidCanonicalizer=BluetoothUUID.getCharacteristic,
     *                        uuid=descriptor,
     *                        allowedUuids=undefined,
     *                        child type="GATT Descriptor")
     * ```
     */
    private GetGATTChildren = async (single: boolean, descriptor?: string | number): Promise<BluetoothRemoteGATTDescriptor[]> => {
        const response = await bluetoothRequest<DiscoverDescriptorsRequest, string[]>(
            'discoverDescriptors',
            {
                device: this.service.device.uuid,
                service: this.service.uuid,
                characteristic: this.uuid,
                instance: this.instance,
                descriptor: descriptor ? BluetoothUUID.getDescriptor(descriptor) : null,
                single: single
            }
        );
        return response.map(uuid =>
            getOrCreateDescriptor(this, uuid)
        );
    }

    // https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTCharacteristic/getDescriptor
    getDescriptor = async (descriptor?: string | number): Promise<BluetoothRemoteGATTDescriptor> => {
        if (typeof descriptor === "undefined") {
            throw new TypeError("Missing 'descriptor' UUID parameter.")
        }
        const descriptors = await this.GetGATTChildren(true, descriptor)
        return descriptors[0]
    }

    // https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTCharacteristic/getDescriptors
    getDescriptors = async (descriptor?: string | number): Promise<BluetoothRemoteGATTDescriptor[]> => {
        return this.GetGATTChildren(false, descriptor)
    }

    // https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTCharacteristic/readValue
    readValue = async (): Promise<DataView> => {
        await bluetoothRequest<ReadCharacteristicRequest, void>(
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
}
