import SwiftUI

public struct BluetoothClientKey: EnvironmentKey {
    public static let defaultValue = BluetoothClient.testValue
}

extension EnvironmentValues {
  public var bluetoothClient: BluetoothClient {
    get { self[BluetoothClientKey.self] }
    set { self[BluetoothClientKey.self] = newValue }
  }
}
