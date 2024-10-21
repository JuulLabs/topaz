
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

extension BluetoothClient {
    public static let testValue = BluetoothClient(request: .testValue, response: .testValue)
}
