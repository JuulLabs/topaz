import SwiftUI
import UIKit

public extension UINavigationBar {
    static func applyCustomizations() {
        appearance().largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.dogpatch(32),
        ]
        appearance().titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.dogpatch(.title),
        ]
    }
}
