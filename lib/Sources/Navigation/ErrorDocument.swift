import Foundation

func genericErrorDocument(error: any Error, url: URL, reason: String?) -> SimpleHtmlDocument {
    let title = "Error \((error as NSError).code)"
    var document = titledErrorDocument(title: title, url: url, reason: reason)
    document.addElement(.p, error.localizedDescription)
    return document
}

func statusCodeErrorDocument(statusCode: Int, url: URL, reason: String?) -> SimpleHtmlDocument {
    let title = "\(statusCode) \(HTTPURLResponse.localizedString(forStatusCode: statusCode).capitalized)"
    return titledErrorDocument(title: title, url: url, reason: reason)
}

private func titledErrorDocument(title: String, url: URL, reason: String?) -> SimpleHtmlDocument {
    var document = SimpleHtmlDocument(title: title)
    document.addElement(.h1, title)
    document.addElement(.p, "Unable to load \(url.absoluteString)")
    if let reason {
        document.addElement(.p, reason)
    }
    return document
}

func shouldPresentErrorDocument(for error: any Error) -> Bool {
    // -999 occurs when an asynchronous load is canceled which may happen on a page reload or on back/forward navigation.
    // It appears this is due to the content being loaded from cache in preference to hitting the remote service.
    (error as NSError).code != -999
}
