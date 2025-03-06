import OSLog

private let log = Logger(subsystem: "JsMessage", category: "JsLogger")
private let consoleLog = Logger(subsystem: "JsMessage", category: "JsConsole")

public final class JsLogger: JsMessageProcessor {
    enum Level {
        case debug, info, warn, error
    }

    public static let handlerName = "logging"
    public let enableDebugLogging = false

    public init() {}

    public func didAttach(to context: JsContext) async {
        // no-op
    }

    public func didDetach(from context: JsContext) async {
        // no-op
    }

    public func process(request: JsMessageRequest, in context: JsContext) async -> JsMessageResponse {
        guard let message = request.body["msg"]?.string else {
            return .error(DomError(name: .encoding, message: "Log body missing required field 'msg'"))
        }
        let level = decodeLevel(request.body["level"]?.string)
        let sensitive = request.body["sensitive"]?.number?.boolValue ?? false
        let isConsole = request.body["console"]?.number?.boolValue ?? false
        let data = request.body["data"]?.dictionary ?? [:]
        sendLog(level: level, isConsole: isConsole, sensitive: sensitive, message: message, data: data)
        return .body([:])
    }

    private func sendLog(level: Level, isConsole: Bool, sensitive: Bool, message: String, data: [String: JsType]?) {
        if isConsole {
            sendLogConsole(level: level, message: message, data: JsType.dictionaryAsString(data))
        } else if sensitive {
            sendLogRedacted(level: level, message: message, data: JsType.dictionaryAsString(data))
        } else {
            sendLogPublic(level: level, message: message, data: JsType.dictionaryAsString(data))
        }
    }

    private func sendLogConsole(level: Level, message: String, data: String) {
        switch level {
        case .debug:
            consoleLog.debug("\(message, privacy: .public) \(data, privacy: .public)")
        case .info:
            consoleLog.info("\(message, privacy: .public) \(data, privacy: .public)")
        case .warn:
            consoleLog.warning("\(message, privacy: .public) \(data, privacy: .public)")
        case .error:
            consoleLog.error("\(message, privacy: .public) \(data, privacy: .public)")
        }
    }

    private func sendLogPublic(level: Level, message: String, data: String) {
        switch level {
        case .debug:
            log.debug("\(message, privacy: .public) \(data, privacy: .public)")
        case .info:
            log.info("\(message, privacy: .public) \(data, privacy: .public)")
        case .warn:
            log.warning("\(message, privacy: .public) \(data, privacy: .public)")
        case .error:
            log.error("\(message, privacy: .public) \(data, privacy: .public)")
        }
    }

    private func sendLogRedacted(level: Level, message: String, data: String) {
        switch level {
        case .debug:
            log.debug("\(message, privacy: .public) \(data, privacy: .private)")
        case .info:
            log.info("\(message, privacy: .public) \(data, privacy: .private)")
        case .warn:
            log.warning("\(message, privacy: .public) \(data, privacy: .private)")
        case .error:
            log.error("\(message, privacy: .public) \(data, privacy: .private)")
        }
    }

    private func decodeLevel(_ string: String?) -> Level {
        guard let string else {
            return .debug
        }
        return switch string {
        case "info": .info
        case "warn": .warn
        case "error": .error
        default: .debug
        }
    }

    private func decodePrivacy(_ string: String?) -> OSLogPrivacy {
        guard let string else {
            return .public
        }
        return switch string {
        case "private": .private
        default: .public
        }
    }
}
