//
//  QRCodeSystem.swift
//  burner
//
//  Created by Sid Rao on 18/09/2025.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

// MARK: - Data Models
/// QR Code data structure for ticket validation
/// NOTE: QR codes are ONLY generated server-side for security (includes hash)
/// Client should never generate QR data - only display what's received from backend
struct QRCodeData: Codable {
    let type: String
    let ticketId: String
    let eventId: String
    let userId: String
    let ticketNumber: String?
    let timestamp: TimeInterval
    let version: String
    let hash: String  // Security hash - validated server-side
}

struct ScannedTicketData {
    let ticketId: String
    let eventId: String
    let userId: String
    let isValid: Bool
    let scanTime: Date
}

// MARK: - QR Code Generator
/// Handles QR code IMAGE generation (display only)
/// IMPORTANT: QR code DATA is generated server-side only for security
struct QRCodeGenerator {
    /// Generates a QR code image from a QR data string
    /// - Parameters:
    ///   - string: The QR code data string (received from backend)
    ///   - size: The size of the QR code image to generate
    /// - Returns: UIImage of the QR code, or nil if generation fails
    static func generateQRCode(from string: String, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        if let outputImage = filter.outputImage {
            let scaleX = size.width / outputImage.extent.size.width
            let scaleY = size.height / outputImage.extent.size.height
            let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

            if let cgimg = context.createCGImage(transformedImage, from: transformedImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }
        return nil
    }

    // REMOVED: generateQRCodeData() function
    // QR code data MUST be generated server-side to include security hash
    // Client should only display QR codes received from Cloud Functions
}

// MARK: - QR Code Validator
struct QRCodeValidator {
    /// Validates a ticket QR code for basic structure
    /// NOTE: Full validation (including hash verification) happens server-side
    /// - Parameters:
    ///   - qrString: The QR code data string to validate
    ///   - eventId: The event ID to validate against
    /// - Returns: True if QR code structure is valid (client-side checks only)
    static func validateTicketQRCode(_ qrString: String, for eventId: String) -> Bool {
        // Parse QR code data
        if let data = qrString.data(using: .utf8),
           let qrData = try? JSONDecoder().decode(QRCodeData.self, from: data) {

            guard qrData.type == "EVENT_TICKET",
                  qrData.eventId == eventId,
                  !qrData.ticketId.isEmpty,
                  !qrData.hash.isEmpty else {  // Ensure hash exists (server-generated)
                return false
            }

            // Check timestamp (tickets shouldn't be too old)
            let age = Date().timeIntervalSince1970 - qrData.timestamp
            guard age < 86400 * 365 else { // Max 1 year
                return false
            }

            return true
        }

        // Fallback validation for legacy simple format (should phase out)
        let components = qrString.components(separatedBy: ":")
        return components.count >= 6 &&
               components[0] == "TICKET" &&
               components[2] == "EVENT" &&
               components[3] == eventId
    }
}

// MARK: - Basic QR Code View
struct QRCodeView: View {
    let data: String
    let size: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    @State private var qrImage: UIImage?
    
    init(
        data: String,
        size: CGFloat = 200,
        backgroundColor: Color = .clear,
        foregroundColor: Color = .black
    ) {
        self.data = data
        self.size = size
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
    
    var body: some View {
        Group {
            if let qrImage = qrImage {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: size, height: size)
                    .background(backgroundColor)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .frame(width: size, height: size)
                    .overlay(
                        VStack {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(foregroundColor)
                            Text("Generating QR...")
                                .font(.caption)
                                .foregroundColor(foregroundColor)
                        }
                    )
            }
        }
        .onAppear {
            generateQRImage()
        }
        .onChange(of: data) { _, _ in
            generateQRImage()
        }
    }
    
    private func generateQRImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            let image = QRCodeGenerator.generateQRCode(
                from: data,
                size: CGSize(width: size * 3, height: size * 3)
            )
            
            DispatchQueue.main.async {
                self.qrImage = image
            }
        }
    }
}

// MARK: - QR Code Scanner View
struct QRCodeScannerView: View {
    @State private var isShowingScanner = false
    @State private var scannedTicket: ScannedTicketData?
    @State private var showingResult = false

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                Text("Venue Scanner")
                    .appSectionHeader()
                    .foregroundColor(.white)

                Button(action: {
                    isShowingScanner = true
                }) {
                    VStack(spacing: 16) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.appLargeIcon)
                            .foregroundColor(.white)

                        Text("Scan Ticket QR Code")
                            .appBody()
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Spacer()
            }
            .padding(20)
            .background(Color.black)
            .sheet(isPresented: $isShowingScanner) {
                Text("QR Scanner Implementation")
                    .font(.title)
                    .foregroundColor(.white)
            }

            if showingResult, let ticket = scannedTicket {
                CustomAlertView(
                    title: "Scan Result",
                    description: "Ticket: \(ticket.ticketId)\nValid: \(ticket.isValid ? "✅" : "❌")",
                    primaryAction: { showingResult = false },
                    primaryActionTitle: "OK",
                    customContent: EmptyView()
                )
                .transition(.opacity)
                .zIndex(1001)
            }
        }
    }
}
