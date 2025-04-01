import Bluetooth
import BluetoothClient
import BluetoothMessage
import Foundation

/**
 The recentlyConnectedPeripherals are those that have successfully been connected.
 It is updated by connect/disconnect events. We use the mis-match between
 recentlyConnectedPeripherals and the underlying CBPeripheral.state to
 recognize when the system has failed to propagate disconnection events.
 Zombies are those with an underlying peripheral state of disconnected where
 we have not seen a disconnect event.

 We see this happen when BLE is disabled via Control Center - the peripherals
 silently change to a disconnected state but the delegate never sends a disconnect.
 This is not the case when BLE is disabled via Settings which does the expected
 thing and immediately triggers the delegate to send a disconnect event.

 Tracking issue: rdar://17036865
 */
struct ZombieDetector {
    private let state: BluetoothState
    private var recentlyConnectedPeripherals: Set<UUID> = []

    init(state: BluetoothState) {
        self.state = state
    }

    mutating func trackZombies(for event: BluetoothEvent) {
        switch event {
        case let event as PeripheralEvent where event.name == .connect:
            recentlyConnectedPeripherals.insert(event.peripheral.id)
        case let DisconnectionEvent.unexpected(peripheral, _):
            recentlyConnectedPeripherals.remove(peripheral.id)
        case let DisconnectionEvent.requested(peripheral):
            recentlyConnectedPeripherals.remove(peripheral.id)
        default:
            break
        }
    }

    /// Consult each peripheral to see if we have any zombies that need to be disconnected.
    /// Zombies are those that we think are connected but have been silently disconnected
    /// due to the system being powered off via Control Center.
    func checkForZombies(for event: BluetoothEvent) async -> [Peripheral] {
        guard let event = event as? SystemStateEvent, event.systemState == .poweredOff else {
            return []
        }
        var zombies: [Peripheral] = []
        for uuid in recentlyConnectedPeripherals {
            if let peripheral = await state.peripherals[uuid], peripheral.connectionState == .disconnected {
                zombies.append(peripheral)
            }
        }
        return zombies
    }
}
