
// Converts Uint8Array to base64 string
export const uint8ArrayToBase64 = (uint8array: Uint8Array): string => {
    return btoa(String.fromCharCode(...uint8array));
}

// Converts base64 string to Uint8Array
export const base64ToUint8Array = (base64: string): Uint8Array => {
    return Uint8Array.from(atob(base64), (m) => m.codePointAt(0))
}

// Converts ArrayBuffer to base64 string
export const arrayBufferToBase64 = (buffer: ArrayBuffer): string => {
    return uint8ArrayToBase64(new Uint8Array(buffer));
}

// Converts base64 string to DataView
export const base64ToDataView = (base64: string): DataView => {
    return new DataView(base64ToUint8Array(base64).buffer);
}

export function copyOf(data: DataView): DataView {
    return new DataView(data.buffer.slice(0))
}

export const isView = (source: ArrayBuffer | ArrayBufferView): source is ArrayBufferView => (source as ArrayBufferView).buffer !== undefined;
