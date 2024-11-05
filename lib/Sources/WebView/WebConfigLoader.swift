import Foundation
import Helpers
import WebKit

/// Mechanism for lazy loading a WKWebViewConfiguration instance with the polyfill scripts injected
public final class WebConfigLoader: Sendable {
    private let cache: DeferredValue<Result<[WKUserScript], any Error>>

    public init(
        scriptResourceNames: [String] = []
    ) {
        guard !scriptResourceNames.isEmpty else {
            cache = .init(initialValue: .success([]))
            return
        }
        cache = .init()
        Task.detached { [cache] in
            do {
                let scripts = try await loadScripts(scriptNames: scriptResourceNames)
                await cache.setValue(.success(scripts))
            } catch {
                await cache.setValue(.failure(error))
            }
        }
    }

    public func loadConfig() async throws -> WKWebViewConfiguration {
        guard let cacheResult = await cache.getValue() else {
            throw LoadError.cancelled
        }
        switch cacheResult {
        case let .success(userScripts):
            return try await newConfig(with: userScripts)
        case let .failure(error):
            throw error
        }
    }

    private func newConfig(with userScripts: [WKUserScript]) async throws -> WKWebViewConfiguration {
        let config = await WKWebViewConfiguration()
        for userScript in userScripts {
            try Task.checkCancellation()
            await config.userContentController.addUserScript(userScript)
        }
        return config
    }
}

extension Array where Element == String {
    public static let topazScripts = ["BluetoothPolyfill"]
}

private enum LoadError: Error, LocalizedError {
    case cancelled
    case resourceNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .cancelled:
            "Operation cancelled"
        case let .resourceNotFound(resourceName):
            "Missing resource file '\(resourceName)'"
        }
    }
}

private func loadScripts(scriptNames: [String]) async throws -> [WKUserScript] {
    try await withThrowingTaskGroup(of: WKUserScript.self) { group in
        for name in scriptNames {
            group.addTask {
                try await loadScript(name)
            }
        }
        var scripts: [WKUserScript] = []
        for try await userScript in group {
            scripts.append(userScript)
        }
        return scripts
    }
}

private func loadScript(_ scriptName: String) async throws -> WKUserScript {
    guard let fileURL = Bundle.module.url(forResource: scriptName, withExtension: "js") else {
        throw LoadError.resourceNotFound(scriptName)
    }
    try Task.checkCancellation()
    let source = try String(contentsOf: fileURL, encoding: .utf8)
    try Task.checkCancellation()
    return await WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false)
}

#if targetEnvironment(simulator)
extension WebConfigLoader {
    @MainActor
    public static func loadImmediate(
        scriptNames: [String] = .topazScripts
    ) -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        let scripts = scriptNames.compactMap {
            Bundle.module
                .url(forResource: $0, withExtension: "js")
                .flatMap { try? String(contentsOf: $0, encoding: .utf8) }
                .map { WKUserScript(source: $0, injectionTime: .atDocumentStart, forMainFrameOnly: false) }
        }
        for script in scripts {
            config.userContentController.addUserScript(script)
        }
        return config
    }
}
#endif
