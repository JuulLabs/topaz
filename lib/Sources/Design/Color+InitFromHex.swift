import SwiftUI

public extension Color {
    init?(hex: String) {
        guard hex.first == "#" else { return nil }
        let red = hex[1..<3]?.hexToDouble()?.scaledByte()
        let blue = hex[3..<5]?.hexToDouble()?.scaledByte()
        let green = hex[5..<7]?.hexToDouble()?.scaledByte()
        let opacity = hex[7..<9]?.hexToDouble()?.scaledByte() ?? 1.0
        switch (red, green, blue) {
        case let (.some(red), .some(green), .some(blue)):
            self = .init(red: red, green: blue, blue: green, opacity: opacity)
        default:
            return nil
        }
    }
}

fileprivate extension String {
    subscript (range: Range<Int>) -> Substring? {
        guard range.lowerBound >= startIndex.utf16Offset(in: self) && range.upperBound <= count else { return nil }
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(startIndex, offsetBy: range.upperBound)
        return self[start ..< end]
    }
}

fileprivate extension String.SubSequence {
    func hexToDouble() -> Double? {
        UInt8(self, radix: 16).map(Double.init)
    }
}

fileprivate extension Double {
    func scaledByte() -> Double {
        return self / 255.0
    }
}
