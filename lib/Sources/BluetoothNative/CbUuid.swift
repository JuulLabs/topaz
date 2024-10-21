import CoreBluetooth

func cbToUuid(_ uuid: CBUUID) -> UUID? {
    let str: String
    if uuid.uuidString.count <= 8 {
        let padCount = max(0, 8 - uuid.uuidString.count)
        let prefix = String(repeating: "0", count: padCount)
        str = prefix + uuid.uuidString + "-0000-1000-8000-00805F9B34FB"
    } else {
        str = uuid.uuidString
    }
    return UUID(uuidString: str)
}
