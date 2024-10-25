import SwiftUI

public enum Dogpatch: String, CaseIterable {
    case sansLight = "DogpatchSans-Light"
    case sansMedium = "DogpatchSans-Medium"
    case sansRegular = "DogpatchSans-Regular"
    case sansBold = "DogpatchSans-Bold"

    public enum Weight {
        case regular, light, medium, bold
    }

    public enum Design {
        case sans
    }

    public enum Typography {
        case launchHeadline
    }

    static func with(weight: Weight, design: Design) -> Dogpatch {
        switch (design, weight) {
        case (.sans, .regular):
            Dogpatch.sansRegular
        case (.sans, .light):
            Dogpatch.sansLight
        case (.sans, .medium):
            Dogpatch.sansMedium
        case (.sans, .bold):
            Dogpatch.sansBold
        }
    }

    func scaleMapping(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: 43
        case .title: 25
        case .title2: 22
        case .title3: 20
        case .headline: 17
        case .subheadline: 14
        case .body: 15
        case .callout: 16
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        @unknown default: 15
        }
    }

    func scaleMapping(for typography: Typography) -> (size: CGFloat, relativeTo: Font.TextStyle) {
        switch typography {
        case .launchHeadline: return (48, .largeTitle)
        }
    }
}

extension Font {
    public static func dogpatch(_ size: CGFloat, weight: Dogpatch.Weight? = nil, design: Dogpatch.Design? = nil) -> Font {
        let design = design ?? .sans
        let weight = weight ?? .regular
        let dogpatch = Dogpatch.with(weight: weight, design: design)
        return .custom(dogpatch.rawValue, fixedSize: size)
    }

    public static func dogpatch(_ style: Font.TextStyle, design: Dogpatch.Design? = nil, weight: Dogpatch.Weight? = nil) -> Font {
        let design = design ?? .sans
        let weight = weight ?? .regular
        let dogpatch = Dogpatch.with(weight: weight, design: design)
        return .custom(dogpatch.rawValue, size: dogpatch.scaleMapping(for: style), relativeTo: style)
    }

    public static func dogpatch(custom typography: Dogpatch.Typography, design: Dogpatch.Design? = nil, weight: Dogpatch.Weight? = nil) -> Font {
        let design = design ?? .sans
        let weight = weight ?? .regular
        let dogpatch = Dogpatch.with(weight: weight, design: design)
        let scale = dogpatch.scaleMapping(for: typography)
        return .custom(dogpatch.rawValue, size: scale.size, relativeTo: scale.relativeTo)
    }
}
