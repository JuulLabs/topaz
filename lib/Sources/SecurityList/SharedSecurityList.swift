import Foundation

/*
 From https://github.com/WebBluetoothCG/registries/blob/master/gatt_blocklist.txt
 Consider automating the construction of this block list but given that at the time
 of writing it hadn't been updated in four years hand coding seems perfectly adequate.
 */
extension SecurityList {
    public static let shared = SecurityList(
        services: [
            UUID(uuidString: "00001812-0000-1000-8000-00805f9b34fb")!: .any,
            UUID(uuidString: "00001530-1212-efde-1523-785feabcd123")!: .any,
            UUID(uuidString: "f000ffc0-0451-4000-b000-000000000000")!: .any,
            UUID(uuidString: "00060000-0000-1000-8000-00805f9b34fb")!: .any,
            UUID(uuidString: "0000fffd-0000-1000-8000-00805f9b34fb")!: .any,
            UUID(uuidString: "0000fff9-0000-1000-8000-00805f9b34fb")!: .any,
            UUID(uuidString: "0000fde2-0000-1000-8000-00805f9b34fb")!: .any,
        ],
        characteristics: [
            UUID(uuidString: "00002a02-0000-1000-8000-00805f9b34fb")!: .writing,
            UUID(uuidString: "00002a03-0000-1000-8000-00805f9b34fb")!: .any,
            UUID(uuidString: "00002a25-0000-1000-8000-00805f9b34fb")!: .any,
        ],
        descriptors: [
            UUID(uuidString: "00002902-0000-1000-8000-00805f9b34fb")!: .writing,
            UUID(uuidString: "00002903-0000-1000-8000-00805f9b34fb")!: .writing,
        ],
    )
}
