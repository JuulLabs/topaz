
// https://webbluetoothcg.github.io/web-bluetooth/#valueevent

export interface ValueEventInit<T> extends EventInit {
    value?: T;
}

export class ValueEvent<T> extends Event {
    value?: T;
    constructor(
        type: string,
        eventInitDict?: ValueEventInit<T>
    ) {
        super(type, eventInitDict);
        this.value = eventInitDict?.value;
    }
};
