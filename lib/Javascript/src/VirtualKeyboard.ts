// Polyfill for https://developer.mozilla.org/en-US/docs/Web/API/VirtualKeyboard

import { EmptyObject } from "./EmptyObject";
import { virtualKeyboardRequest } from "./WebKit";

type SetOverlaysContentRequest = {
    enable: boolean;
}

type ShowRequest = {
    show: boolean;
}

// https://www.w3.org/TR/virtual-keyboard/#the-virtualkeyboard-interface
export class VirtualKeyboard extends EventTarget {
    private _boundingRect: DOMRect;
    private _overlaysContent: boolean;

    get boundingRect(): DOMRect {
        return this._boundingRect;
    }

    get overlaysContent(): boolean {
        return this._overlaysContent;
    }

    set overlaysContent(value: boolean) {
        this._overlaysContent = value;
        virtualKeyboardRequest<SetOverlaysContentRequest, EmptyObject>(
            'setOverlaysContent',
            { enable: value }
        );
    }

    constructor() {
        super();
        this._boundingRect = new DOMRect(0, 0, 0, 0);
        this._overlaysContent = false;
    }

    show = () => {
        virtualKeyboardRequest<ShowRequest, EmptyObject>(
            'show',
            { show: true }
        );
        console.warn('VirtualKeyboard.show() is not supported by this browser.');
    }

    hide = () => {
        virtualKeyboardRequest<ShowRequest, EmptyObject>(
            'show',
            { show: false }
        );
        console.warn('VirtualKeyboard.hide() is not supported by this browser.');
    }

    _updateBoundingRect = (data: { x: number; y: number; width: number; height: number }) => {
        this._boundingRect = new DOMRect(data.x, data.y, data.width, data.height);
    }
}
