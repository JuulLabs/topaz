import Bluetooth
import BluetoothClient
import CoreBluetooth
import Foundation

extension BluetoothClient {
    public static let liveValue = {
        let coordinator = Coordinator()
        let responseClient = ResponseClient(events: coordinator.events.stream)
        let requestClient = liveRequestClient(coordinator: coordinator)
        return BluetoothClient(request: requestClient, response: responseClient)
    }()
}

private func liveRequestClient(coordinator: Coordinator) -> RequestClient {
    return RequestClient(
        enable: { coordinator.enable() },
        disable: { coordinator.disable() },
        scan: { coordinator.startScanning(filter: $0) },
        connect: { coordinator.connect(peripheral: $0) },
        disconnect: { coordinator.disconnect(peripheral: $0) },
        discoverServices: { coordinator.discoverServices(peripheral: $0, filter: $1) },
        discoverCharacteristics: { coordinator.discoverCharacteristics(peripheral: $0, filter: $1) }
    )
}
