import { nfcRequest } from "./WebKit";

type ScanRequest = {
    id: string;
}

type ScanResponse = {
}

let readers = new Map<string, NDEFReader>();

export class NDEFReader extends EventTarget {
    id: string;

    constructor() {
        super();
        this.id = readers.size.toString();
        readers.set(this.id, this);
    }


    scan = async (): Promise<void> => {
        const response = await nfcRequest<ScanRequest, ScanResponse>(
            'scan',
            { id: this.id }
        );
        return;
    }
}

export const getReader = (id: string): NDEFReader => {
    return readers.get(id);
}
