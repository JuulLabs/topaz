import Bluetooth
import Foundation

protocol BluetoothEffector: Sendable {
    func bluetoothReadyState() async throws
    func runEffect(action: Message.Action, uuid: UUID, effect: @Sendable (RequestClient) -> Void) async throws
}
