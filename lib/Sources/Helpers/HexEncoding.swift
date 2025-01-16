import Foundation

public struct HexEncodingOptions: Sendable, OptionSet {
    public static let upper = HexEncodingOptions(rawValue: 1 << 0)
    public static let prefix = HexEncodingOptions(rawValue: 1 << 1)

    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public extension Sequence where Element: CVarArg {
    func hexEncodedString(
        _ options: HexEncodingOptions = [],
        separator: String = ""
    ) -> String {
        let format = options.contains(.upper) ? "%02hhX" : "%02hhx"
        let output = map { String(format: format, $0) }.joined(separator: separator)
        return options.contains(.prefix) && !output.isEmpty ? "0x" + output : output
    }
}
