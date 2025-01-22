
struct AppConfiguration {
    let enableDebugLogging: Bool
}

extension AppConfiguration {
    static let debug: AppConfiguration = .init(
        enableDebugLogging: true
    )
}

extension AppConfiguration {
    static let release: AppConfiguration = .init(
        enableDebugLogging: false
    )
}

#if DEBUG
let appConfig: AppConfiguration = .debug
#else
let appConfig: AppConfiguration = .release
#endif
