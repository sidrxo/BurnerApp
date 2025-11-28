import Foundation
@preconcurrency import CoreNFC
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
    nonisolated func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        // Session is now active and ready to scan
        Task { @MainActor in
            print("✅ NFC session is now active and ready to scan")
        }
    }
    
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
        print("🎯 didDetectNDEFs called with \(messages.count) messages")
        // This is called when invalidateAfterFirstRead is true
        Task { @MainActor in
            await processMessages(messages, session: session)
        }
    }
    
    nonisolated func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        print("🏷️ didDetect tags called with \(tags.count) tags")
        // This is called for reading operations
        guard tags.count == 1 else {
            session.alertMessage = "Please scan only one tag"
            session.invalidate()
            return
        }
        
        let tag = tags[0]
        
        // Capture session and tag as nonisolated(unsafe) to avoid Sendable warnings
        // This is safe because NFC operations are properly serialized by the framework
        nonisolated(unsafe) let capturedSession = session
        nonisolated(unsafe) let capturedTag = tag
        
        capturedSession.connect(to: capturedTag) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Connection failed: \(error.localizedDescription)")
                capturedSession.alertMessage = "Connection failed: \(error.localizedDescription)"
                capturedSession.invalidate()
                return
            }
            
            print("✅ Connected to tag, reading NDEF...")
            
            // Read the tag
            capturedTag.readNDEF { message, error in
                if let error = error {
                    print("❌ Read failed: \(error.localizedDescription)")
                    capturedSession.alertMessage = "Read failed: \(error.localizedDescription)"
                    capturedSession.invalidate()
                    return
                }
                
                if let message = message {
                    print("✅ Successfully read NDEF message")
                    Task { @MainActor in
                        await self.processMessages([message], session: capturedSession)
                    }
                } else {
                    print("⚠️ No message found on tag")
                    capturedSession.alertMessage = "No data found on tag"
                    capturedSession.invalidate()
                }
            }
        }
    }
    
    private func processMessages(_ messages: [NFCNDEFMessage], session: NFCNDEFReaderSession) async {
        print("📱 Processing \(messages.count) NDEF message(s)")
        
        for message in messages {
            print("📦 Message has \(message.records.count) record(s)")
            
            for record in message.records {
                print("🔍 Record type: \(String(data: record.type, encoding: .utf8) ?? "unknown")")
                print("🔍 Type format: \(record.typeNameFormat.rawValue)")
                
                // Check if this is a text record
                if record.typeNameFormat == .nfcWellKnown,
                   String(data: record.type, encoding: .utf8) == "T" {
                    print("✅ Found text record")
                    
                
                    
                    let payloadData = record.payload
                    guard payloadData.count > 0 else {
                        print("❌ Empty payload")
                        continue
                    }
                    
                    let statusByte = payloadData[0]
                    let languageCodeLength = Int(statusByte & 0x3F) // Lower 6 bits
                    
                    print("📊 Status byte: \(statusByte), Language code length: \(languageCodeLength)")
                    
                    guard payloadData.count > languageCodeLength else {
                        print("❌ Payload too short")
                        continue
                    }
                    
                    // Skip status byte + language code to get actual text
                    let textData = payloadData.suffix(from: 1 + languageCodeLength)
                    
                    if let text = String(data: textData, encoding: .utf8) {
                        print("📝 Decoded text: '\(text)'")
                        print("🔑 Expected code: '\(unlockCode)'")
                        
                        // Check if this matches our static unlock code
                        if text == unlockCode {
                            print("✅✅✅ MATCH! Unlocking...")
                            session.alertMessage = "✅ Unlock successful!"
                            session.invalidate()
                            
                            // Trigger unlock
                            onUnlockSuccess?()
                            onUnlockSuccess = nil
                            return
                        } else {
                            print("❌ No match - got '\(text)' expected '\(unlockCode)'")
                        }
                    } else {
                        print("❌ Could not decode text as UTF-8")
                    }
                } else {
                    print("⚠️ Not a text record - skipping")
                }
            }
        }
        
        // No valid unlock code found
        print("❌ No valid unlock code found in any record")
        session.alertMessage = "❌ Not an unlock tag"
        session.invalidate()
        lastError = "This tag doesn't contain the unlock code"
    }
}
