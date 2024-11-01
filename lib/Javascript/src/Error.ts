// WebKit wraps the string we return from WKScriptMessageHandlerWithReply into an exception-like object
type WebKitError = {
    name: string;    // Seems to always be "Error"
    message: string; // This is our JSON string
}

// Our error message is structured JSON with this shape which we decode from WebKitError.message:
type TopazError = {
    name: string;
    msg: string;
}

const transformToDOMException = (error: WebKitError): DOMException => {
    try {
        const decoded = JSON.parse(error.message) as TopazError;
        return new DOMException(decoded.msg, decoded.name);
    } catch (e) {
        return new DOMException(`${e} when decoding "${error}"`, 'EncodingError');
    }
}

export const rethrowAsDOMException = (error: WebKitError) => {
    throw transformToDOMException(error);
}
