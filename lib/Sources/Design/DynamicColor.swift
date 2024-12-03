import SwiftUI

public enum ShadeLevel: CGFloat {
    case zero = 0.0
    case one = 0.1
    case two = 0.2
    case three = 0.3
    case four = 0.4
    case five = 0.5
    case six = 0.6
    case seven = 0.7
    case eight = 0.8
    case nine = 0.9
    case ten = 1.0
}

public typealias TintLevel = ShadeLevel
public typealias ClearedLevel = ShadeLevel

private struct RGBAComponents {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat

    init?(_ color: Color) {
        guard let components = color.cgColor?.components else { return nil }
        guard let cgColor = color.cgColor else { return nil }
        red = components[0]
        green = components[1]
        blue = components[2]
        alpha = cgColor.alpha
    }
}

private func mix(_ color: Color, with otherColor: Color, weight: CGFloat) -> Color {
    guard let color1 = RGBAComponents(color), let color2 = RGBAComponents(otherColor) else {
        return color
    }

    let red   = color1.red + (weight * (color2.red - color1.red))
    let green = color1.green + (weight * (color2.green - color1.green))
    let blue  = color1.blue + (weight * (color2.blue - color1.blue))
    let alpha = color1.alpha + (weight * (color2.alpha - color1.alpha))

    return Color(red: red, green: green, blue: blue, opacity: alpha)
}

public extension Color {
    func cleared(level: ClearedLevel) -> Color {
        return self.opacity(level.rawValue)
    }

    func tinted(weight: CGFloat) -> Color {
        return Design.mix(self, with: .white, weight: weight)
    }

    func tinted(level: TintLevel) -> Color {
        return Design.mix(self, with: .white, weight: level.rawValue)
    }

    func shaded(weight: CGFloat) -> Color {
        return Design.mix(self, with: .black, weight: weight)
    }

    func shaded(level: ShadeLevel) -> Color {
        return Design.mix(self, with: .black, weight: level.rawValue)
    }

    static func grayScale(_ level: CGFloat) -> Color {
        Color(red: level, green: level, blue: level)
    }

    func interpolate(between otherColor: Color, by percentage: CGFloat) -> Color {
        return Design.mix(self, with: otherColor, weight: percentage)
    }
}
