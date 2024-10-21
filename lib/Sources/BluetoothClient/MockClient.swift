import Bluetooth
import Helpers

extension BluetoothClient {
    public static func mockClient(
        systemState: (@Sendable () -> SystemState)? = nil
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

        return BluetoothClient(request: requestClient, response: responseClient)
    }
}
