import { appLog } from "./WebKit"

const safeStringify = (obj: any): string => {
    try {
        return JSON.stringify(obj)
    }
    catch (e) {
        return `Cannot stringify object ${e.message}`
    }
}

// TODO: Some more work to do here to implement the full-spec properly:
// https://console.spec.whatwg.org/#formatting-specifiers
const percentInterpolation = (format: string, args: any[]): string => {
    if (typeof(format) !== 'string') {
        return;
    }
    if (args.length === 0) {
        return format;
    }
    if (!/%s|%v|%o|%d|%i|%f/.test(format)) {
        return;
    }
    return args.reduce((str, val) => str.replace(/%s|%v|%o|%d|%i|%f/, val), format);
}

const logOverride = (level: string, args: IArguments) => {
    if (args.length === 0) {
        return;
    }

    let formatted = percentInterpolation(args[0], Array.prototype.slice.call(args, 1));
    if (formatted) {
        appLog({
            level: level,
            msg: formatted.substring(0, 2048),
            console: true,
            sensitive: false,
        });
        return;
    }

    let strings = [];
    for (let i = 0; i < args.length; i++) {
        const arg = args[i];
        if (typeof(arg) === 'undefined') {
            strings.push('undefined');
        } else if (typeof(arg) === 'object') {
            strings.push(safeStringify(arg).substring(0, 2048));
        } else if (typeof(arg) === 'string') {
            strings.push(arg.substring(0, 2048));
        } else {
            strings.push(arg.toString().substring(0, 2048));
        }
    }
    appLog({
        level: level,
        msg: strings.join(' '),
        console: true,
        sensitive: false,
    });
}

export const setupLogging = () => {
    let originalLog = globalThis.console.log
    let originalWarn = globalThis.console.warn
    let originalError = globalThis.console.error
    let originalDebug = globalThis.console.debug

    globalThis.console.log = function() {
        originalLog.apply(null, arguments);
        logOverride('debug', arguments);
    }

    globalThis.console.warn = function() {
        originalWarn.apply(null, arguments);
        logOverride('warn', arguments);
    }

    globalThis.console.error = function() {
        originalError.apply(null, arguments);
        logOverride('error', arguments);
    }

    globalThis.console.debug = function() {
        originalDebug.apply(null, arguments);
        logOverride('debug', arguments);
    }

    window.addEventListener('error', (e) => {
        appLog({
            level: 'error',
            msg: `Uncaught ${e}`,
            sensitive: false,
        });
    });
}
