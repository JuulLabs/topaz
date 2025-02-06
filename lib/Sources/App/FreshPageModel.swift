//import Foundation
import Observation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
@Observable
public final class FreshPageModel {
    let searchBarModel: SearchBarModel
    var isLoading: Bool
    var searchBarFocusOnLoad: Bool

    init(
        searchBarModel: SearchBarModel,
        isLoading: Bool = false,
        searchBarFocusOnLoad: Bool = true
    ) {
        self.searchBarModel = searchBarModel
        self.isLoading = isLoading
        self.searchBarFocusOnLoad = searchBarFocusOnLoad

//        if UIPasteboard.general.hasURLs {
//
//            if let url = UIPasteboard.general.url {
//                print(url)
//                self.searchBarModel.searchString = url.absoluteString
//                self.searchBarModel.didSubmitSearchString()
//            }
//
//            UIPasteboard().itemSet(withPasteboardTypes: [UTType.url.identifier])
//            let types = UIPasteboard().types
////            UTTypeLinkPresentationMetadata
////            UTType.linkPresentationMetadata
////            UTTypeLinkPresentationMetadata
//            UTType.url
//            let thigns = UIPasteboard.general.types
////            let items = UIPasteboard.general.items
////            let url = UIPasteboard.general.url
//            print(thigns)
//            print(types)
////            print(url)
//            print("")
//        }
//        print(content)
    }

    func onAppear() {
        if searchBarFocusOnLoad {
            searchBarModel.focusedField = .searchBar
        }
    }
}
