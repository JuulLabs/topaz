import CoreText
import Foundation

/// Invoke this from main app launch to load the fonts from the SPM bundle
public func registerFonts() {
    Dogpatch.allCases.forEach { font in
        registerFont(bundle: .module, name: font.rawValue, ext: "ttf")
    }
}

private func registerFont(bundle: Bundle, name: String, ext: String) {
    guard let url = bundle.url(forResource: name, withExtension: ext) else {
        fatalError("Unable to locate font \(name).\(ext)")
    }
    var error: Unmanaged<CFError>?
    if !CTFontManagerRegisterFontsForURL(url as CFURL, .none, &error) {
        let message = error?.takeRetainedValue().localizedDescription ?? "no error"
        print("Register font \(name) failed: \(message)")
    }
}
