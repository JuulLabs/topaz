import Bluetooth
import Helpers
import Foundation

extension BluetoothClient {
    public static func mockClient(
        systemState: (@Sendable () -> SystemState)? = nil,
        startScanning: (@Sendable (Filter) -> Void)? = nil,
        stopScanning: (@Sendable () -> Void)? = nil
    ) -> Self {

        let delegateStream = EmissionStream<DelegateEvent>()
        var responseClient = ResponseClient.testValue
        responseClient.events = delegateStream.stream

        var requestClient = RequestClient.testValue
        requestClient.enable = {
            if let systemState {
                delegateStream.emit(.systemState(systemState()))
            }
        }
        requestClient.startScanning = { startScanning?($0) }
        requestClient.stopScanning = { stopScanning?() }

        return BluetoothClient(request: requestClient, response: responseClient)
    }
}
