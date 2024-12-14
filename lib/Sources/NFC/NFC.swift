import CoreNFC
import Foundation
import JsMessage

public class NFCEngine: JsMessageProcessor, @unchecked Sendable {
    public let handlerName: String = "nfc"
    private var context: JsContext?

    public init() {
    }

    public func didAttach(to context: JsContext) async {
        self.context = context
    }
    
    public func didDetach(from context: JsContext) async {
        self.context = nil
    }
    
    public func process(request: JsMessageRequest) async -> JsMessageResponse {
        print("Got request: \(request)")
        do {
            return try await processAction(request: request)
        } catch {
            return .error(error.toDomError())
        }
    }

    func processAction(request: JsMessageRequest) async throws -> JsMessageResponse {
        guard let actionString = request.body["action"]?.string else {
            throw NFCError.missingAction
        }
        switch actionString {
        case "scan":
            guard let id = request.body["data"]?.dictionary?["id"]?.string else {
                throw NFCError.missingId
            }
            readTag(id: id)
            return .body([:])
        default:
            throw NFCError.badAction
        }
    }

    func readTag(id: String) {
        let ndefReader = NativeNFCClient()
        ndefReader.onTag = { tag, status, error in
            ndefReader.read(tag: tag) { message in
                let body = self.responseDictionary(records: message.records)
                let event = JsEvent(targetId: id, eventName: "reading", body: body)
                Task { [context = self.context] in
                    try? await Task.sleep(for: .seconds(1))
                    let result = await context?.sendEvent(event)
                    print("Event send result: \(result)")
                }
            }
        }
        ndefReader.beginScanning()
    }

    func responseDictionary(records: [NFCNDEFPayload]) -> [String: JsConvertable] {
        let serial = records.first.flatMap { $0.wellKnownTypeTextPayload().0 } ?? "none"
        return [
            "serialNumber": serial,
            "message": [
                "records": [],
            ]
        ]
    }

}

public enum NFCError: Error {
    case fail
    case missingAction
    case badAction
    case missingId
}

extension NFCError: DomErrorConvertable {
    public var domErrorName: DomErrorName { .operataion }
}


public final class NativeNFCClient: NSObject, NFCNDEFReaderSessionDelegate, @unchecked Sendable {
    private var session: NFCNDEFReaderSession?

    public var onTag: ((NFCNDEFTag, NFCNDEFStatus, Error?) -> Void)?

    public func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        print("readerSessionDidBecomeActive")
    }

    public func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [any NFCNDEFTag]) {
        print("readerSessionDidDetectTags: \(tags)")
        guard let tag = tags.first else {
            print("no tags")
            return
        }
        tag.queryNDEFStatus(completionHandler: { status, capacity, error in
            print("queryNDEFStatus: \(status) n=\(capacity) error=\(error?.localizedDescription ?? "")")
            self.onTag?(tag, status, error)
        })
    }

    public func read(tag: NFCNDEFTag, completion: @escaping (NFCNDEFMessage) -> Void) {
        tag.readNDEF(completionHandler: { message, error in
            if let error {
                print("readNDEF Error: \(error.localizedDescription)")
            } else {
                print("readNDEF Ok: \(message?.description ?? "nil message")")
                if let message {
                    completion(message)
                }
            }
            self.endScanning(errorMessage: error?.localizedDescription)
        })
    }

    public func write(tag: NFCNDEFTag, message: NFCNDEFMessage, completion: @escaping (Error?) -> Void) {
        tag.writeNDEF(message, completionHandler: { error in
            completion(error)
            if let error {
                print("writeNDEF Error: \(error.localizedDescription)")
                return
            } else {
                print("writeNDEF Ok")
            }
            self.endScanning(errorMessage: error?.localizedDescription)
        })
    }

    public func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: any Error) {
        print("didInvalidateWithError: \(error.localizedDescription)")
        endScanning(errorMessage: error.localizedDescription)
    }

    public func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        print("messaegs: \(messages)")
        session.invalidate()
    }


    public func beginScanning() {
        guard NFCNDEFReaderSession.readingAvailable else {
            print("Not supported")
            return
        }
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session?.alertMessage = "Hold your device near the phone"
        session?.begin()
    }

    public func endScanning(errorMessage: String? = nil) {
        if let errorMessage {
            session?.invalidate(errorMessage: errorMessage)
        } else {
            session?.invalidate()
        }
        //delegate = nil
        session = nil
    }

}
