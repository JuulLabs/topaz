
public struct BluetoothClient: Sendable {
    public var request: RequestClient
    public var response: ResponseClient

    public init(
        request: RequestClient,
        response: ResponseClient
    ) {
        self.request = request
        self.response = response
    }
}
