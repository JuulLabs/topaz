import Foundation

public struct ServiceData: Equatable, Sendable {
    private let rawData: [UUID:Data]

    public init(_ rawData: [UUID:Data]) {
        self.rawData = rawData
    }

    public func data(for uuid: UUID) -> Data? {
        return rawData[uuid]
    }
}

extension ServiceData: CustomStringConvertible {
    public var description: String {
        return "[" + rawData.map { uuid, data in
            let dataAsString = data.map { String(format: "%02X", $0) }.joined(separator: " ")
            return "ServiceData(UUID=\(uuid), Data=[\(dataAsString)])"
        }.joined(separator: ", ") + "]"
    }
}
