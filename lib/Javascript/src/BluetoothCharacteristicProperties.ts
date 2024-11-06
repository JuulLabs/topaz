// https://developer.mozilla.org/en-US/docs/Web/API/BluetoothCharacteristicProperties
export class BluetoothCharacteristicProperties extends EventTarget {
    authenticatedSignedWrites: boolean;
    broadcast: boolean;
    indicate: boolean;
    notify: boolean;
    read: boolean;
    reliableWrite: boolean;
    writableAuxiliaries: boolean;
    write: boolean;
    writeWithoutResponse: boolean;

    constructor(
        authenticatedSignedWrites: boolean,
        broadcast: boolean,
        indicate: boolean,
        notify: boolean,
        read: boolean,
        reliableWrite: boolean,
        writableAuxiliaries: boolean,
        write: boolean,
        writeWithoutResponse: boolean,
    ) {
        super();
        this.authenticatedSignedWrites = authenticatedSignedWrites;
        this.broadcast = broadcast;
        this.indicate = indicate;
        this.notify = notify;
        this.read = read;
        this.reliableWrite = reliableWrite;
        this.writableAuxiliaries = writableAuxiliaries;
        this.write = write;
        this.writeWithoutResponse = writeWithoutResponse;
    }
}
