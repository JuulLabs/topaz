import Foundation

public struct ManufacturerData: Equatable, Sendable {
    public let code: UInt16
    public let data: Data

    public init(code: UInt16, data: Data) {
        self.code = code
        self.data = data
    }
}

extension ManufacturerData {
    public static func parse(from rawData: Data) -> Self? {
        guard rawData.count >= 2 else { return nil }
        let code = rawData.withUnsafeBytes { bytes in
            UInt16(littleEndian: bytes.load(as: UInt16.self))
        }
        return .init(code: code, data: rawData.dropFirst(2))
    }
}

extension ManufacturerData: CustomStringConvertible {
    public var description: String {
        let codeAsString = String(format: "0x%04X", code)
        let dataAsString = data.map { String(format: "%02X", $0) }.joined(separator: " ")
        return "ManufacturerData(Code=\(codeAsString), Data=[\(dataAsString)])"
    }
}
