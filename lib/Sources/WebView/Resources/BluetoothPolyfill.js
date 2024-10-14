
// A function that returns a function that takes some data and returns a promise that sends a
// BLE message to the app and resolves with a post-message response that we then map over
const messageSender = function (name, mapResponse) {
    return (data) => window.webkit.messageHandlers.bluetooth.postMessage({
            action: name,
            data: data
        }).then(mapResponse);
}


// Polyfill https://developer.mozilla.org/en-US/docs/Web/API/Bluetooth

const Bluetooth = {
    getAvailability: messageSender('getAvailability', (response) => {
        return response.isAvailable;
    }),
};

if (navigator.bluetooth === undefined) {
    navigator.bluetooth = Bluetooth;
}
