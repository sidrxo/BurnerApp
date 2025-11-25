import Foundation
import CoreNFC
import Combine

@MainActor
class NFCUnlockManager: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var scanMessage = "Hold your phone near an NFC tag"
    @Published var lastError: String?
    
    private var readerSession: NFCNDEFReaderSession?
    private var onUnlockSuccess: (() -> Void)?
    
    // Static unlock code - simple and straightforward
    private let unlockCode = "BURNER_UNLOCK_2024"
    
    // MARK: - Check NFC Availability
    func isNFCAvailable() -> Bool {
        return NFCNDEFReaderSession.readingAvailable
    }
    
    // MARK: - Start Reading for Unlock
    func startReadingForUnlock(onSuccess: @escaping () -> Void) {
        guard NFCNDEFReaderSession.readingAvailable else {
            lastError = "NFC is not available on this device"
            return
        }
        
        self.onUnlockSuccess = onSuccess
        
        readerSession = NFCNDEFReaderSession(
            delegate: self,
            queue: nil,
            invalidateAfterFirstRead: true
        )
        
        readerSession?.alertMessage = "Hold your phone near the unlock tag"
        readerSession?.begin()
        
        isScanning = true
        scanMessage = "Scanning for unlock tag..."
        lastError = nil
    }
    
    // MARK: - Stop Scanning
    func stopScanning() {
        readerSession?.invalidate()
        readerSession = nil
        isScanning = false
    }
}

// MARK: - NFCNDEFReaderSessionDelegate
extension NFCUnlockManager: NFCNDEFReaderSessionDelegate {
    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        Task { @MainActor in
            isScanning = false
            
            if let nfcError = error as? NFCReaderError {
                switch nfcError.code {
                case .readerSessionInvalidationErrorUserCanceled:
                    scanMessage = "Scan cancelled"
                case .readerSessionInvalidationErrorSessionTimeout:
                    lastError = "Scan timed out"
                case .readerSessionInvalidationErrorFirstNDEFTagRead:
                    // This is actually success for invalidateAfterFirstRead
                    break
                default:
                    lastError = "NFC Error: \(nfcError.localizedDescription)"
                }
            }
        }
    }
    
    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // This is called when invalidateAfterFirstRead is true
        Task { @MainActor in
            await processMessages(messages, session: session)
        }
    }
    
    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        // This is called for reading operations
        guard tags.count == 1 else {
            session.alertMessage = "Please scan only one tag"
            session.invalidate()
            return
        }
        
        let tag = tags[0]
        
        session.connect(to: tag) { error in
            if let error = error {
                session.alertMessage = "Connection failed: \(error.localizedDescription)"
                session.invalidate()
                return
            }
            
            // Read the tag
            tag.readNDEF { message, error in
                if let error = error {
                    session.alertMessage = "Read failed: \(error.localizedDescription)"
                    session.invalidate()
                    return
                }
                
                if let message = message {
                    Task { @MainActor in
                        await self.processMessages([message], session: session)
                    }
                }
            }
        }
    }
    
    private func processMessages(_ messages: [NFCNDEFMessage], session: NFCNDEFReaderSession) async {
        for message in messages {
            for record in message.records {
                // Check if this is a text record
                if record.typeNameFormat == .nfcWellKnown,
                   String(data: record.type, encoding: .utf8) == "T" {
                    // Parse text record
                    if let payload = String(data: record.payload, encoding: .utf8) {
                        // Text records start with language code length byte, skip it
                        let text = String(payload.dropFirst())
                        
                        // Check if this matches our static unlock code
                        if text == unlockCode {
                            session.alertMessage = "✅ Unlock successful!"
                            session.invalidate()
                            
                            // Trigger unlock
                            onUnlockSuccess?()
                            onUnlockSuccess = nil
                            return
                        }
                    }
                }
            }
        }
        
        // No valid unlock code found
        session.alertMessage = "❌ Not an unlock tag"
        session.invalidate()
        lastError = "This tag doesn't contain the unlock code"
    }
}
