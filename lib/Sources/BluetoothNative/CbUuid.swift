import CoreBluetooth

// The Bluetooth SIG reserved base UUID least significant 12 bytes:
private let baseUuidData = Data([0x00, 0x00, 0x10, 0x00, 0x80, 0x00, 0x00, 0x80, 0x5F, 0x9B, 0x34, 0xFB])

extension CBUUID {
    var regularUuid: UUID {
        cbToUuid(self)
    }
}

func cbToUuid(_ uuid: CBUUID) -> UUID {
    let data: Data
    if uuid.data.count <= 4 {
        let padCount = max(0, 4 - uuid.data.count)
        let prefix = Data(count: padCount)
        data = prefix + uuid.data + baseUuidData
    } else {
        data = uuid.data
    }
    return data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> UUID in
        let uuid = pointer.load(as: uuid_t.self)
        return UUID(uuid: uuid)
    }
}
