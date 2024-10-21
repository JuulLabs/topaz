import { BluetoothDevice } from "./BluetoothDevice";
import { bluetoothRequest } from "./WebKit";

type Options = {
    // external
}

type GetAvailabilityResponse = {
    isAvailable: boolean;
}

type RequestDeviceRequest = {
    options: Options;
}

type RequestDeviceResponse = {
    id: string;
    name?: string;
}

// https://developer.mozilla.org/en-US/docs/Web/API/Bluetooth
export class Bluetooth extends EventTarget {

    getAvailability = async function() {
        const response = await bluetoothRequest<undefined, GetAvailabilityResponse>(
            'getAvailability'
        );
        return response.isAvailable;
    }

    getDevices = async function() {
        const response = await bluetoothRequest<undefined, RequestDeviceResponse[]>(
            'getDevices'
        );
        return response.map(device => new BluetoothDevice(device.id, device.name));
    }

    requestDevice = async function(options?: Options) {
        const response = await bluetoothRequest<RequestDeviceRequest, RequestDeviceResponse>(
            'requestDevice',
            { options: options }
        );
        return new BluetoothDevice(response.id, response.name);
    }
}
