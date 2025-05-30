import Bluetooth
import BluetoothClient
@testable import BluetoothEngine
import BluetoothMessage
import EventBus
import Foundation
import TestHelpers
import Testing

@Suite
struct ZombieDetectorTests {

    private let connectedPeripheral = FakePeripheral(id: UUID(n: 0), connectionState: .connected)
    private let disconnectedPeripheral = FakePeripheral(id: UUID(n: 0), connectionState: .disconnected)

    @Test
    func checkForZombies_powerOffEventAfterPeripheralConnectedAndNotDisconnected_detectsZombie() async {
        let state = BluetoothState(
            systemState: .poweredOn,
            peripherals: [disconnectedPeripheral]
        )
        var sut = ZombieDetector(state: state)
        sut.trackZombies(for: PeripheralEvent(.connect, connectedPeripheral))
        let zombies = await sut.checkForZombies(for: SystemStateEvent(.poweredOff))
        #expect(zombies.count == 1)
    }

    @Test
    func checkForZombies_powerOffEventAfterPeripheralConnectedAndThenRequestedDisconnect_isEmpty() async {
        let state = BluetoothState(
            systemState: .poweredOn,
            peripherals: [disconnectedPeripheral]
        )
        var sut = ZombieDetector(state: state)
        sut.trackZombies(for: PeripheralEvent(.connect, connectedPeripheral))
        sut.trackZombies(for: DisconnectionEvent.requested(disconnectedPeripheral))
        let zombies = await sut.checkForZombies(for: SystemStateEvent(.poweredOff))
        #expect(zombies.isEmpty)
    }

    @Test
    func checkForZombies_powerOffEventAfterPeripheralConnectedAndThenUexpectedDisconnect_isEmpty() async {
        let state = BluetoothState(
            systemState: .poweredOn,
            peripherals: [disconnectedPeripheral]
        )
        var sut = ZombieDetector(state: state)
        sut.trackZombies(for: PeripheralEvent(.connect, connectedPeripheral))
        sut.trackZombies(for: DisconnectionEvent.unexpected(disconnectedPeripheral, BluetoothError.unknown))
        let zombies = await sut.checkForZombies(for: SystemStateEvent(.poweredOff))
        #expect(zombies.isEmpty)
    }

    @Test
    func checkForZombies_powerOffEventAfterTwoPeripheralsConnectedAndOneDisconnects_detectsOneZombie() async {
        let state = BluetoothState(
            systemState: .poweredOn,
            peripherals: [
                FakePeripheral(id: UUID(n: 0), connectionState: .disconnected),
                FakePeripheral(id: UUID(n: 1), connectionState: .disconnected),
            ]
        )
        var sut = ZombieDetector(state: state)
        sut.trackZombies(for: PeripheralEvent(.connect, FakePeripheral(id: UUID(n: 0), connectionState: .connected)))
        sut.trackZombies(for: PeripheralEvent(.connect, FakePeripheral(id: UUID(n: 1), connectionState: .connected)))
        sut.trackZombies(for: DisconnectionEvent.requested(FakePeripheral(id: UUID(n: 0), connectionState: .disconnected)))
        let zombies = await sut.checkForZombies(for: SystemStateEvent(.poweredOff))
        #expect(zombies.count == 1)
        #expect(zombies.first?.id == UUID(n: 1))
    }
}
