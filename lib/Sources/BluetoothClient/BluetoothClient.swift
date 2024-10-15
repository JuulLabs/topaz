
public struct BluetoothClient: Sendable {
    public let request: RequestClient
    public let response: ResponseClient

    public init(
        request: RequestClient,
        response: ResponseClient
    ) {
        self.request = request
        self.response = response
    }
}
