//
//  QRCodeGenerator.swift
//  burner
//
//  Created by Sid Rao on 18/09/2025.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

// MARK: - QR Code Generator
struct QRCodeGenerator {
    static func generateQRCode(from string: String, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)
        
        // Set error correction level (L, M, Q, H)
        filter.correctionLevel = "M"
        
        if let outputImage = filter.outputImage {
            // Scale the image to desired size
            let scaleX = size.width / outputImage.extent.size.width
            let scaleY = size.height / outputImage.extent.size.height
            let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
            
            if let cgimg = context.createCGImage(transformedImage, from: transformedImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }
        return nil
    }
    
    static func generateQRCodeData(ticketId: String, eventId: String, userId: String) -> String {
        // Create a structured QR code data format
        let qrData = QRCodeData(
            type: "EVENT_TICKET",
            ticketId: ticketId,
            eventId: eventId,
            userId: userId,
            timestamp: Date().timeIntervalSince1970,
            version: "1.0"
        )
        
        // Convert to JSON string
        if let jsonData = try? JSONEncoder().encode(qrData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        // Fallback to simple format
        return "TICKET:\(ticketId):EVENT:\(eventId):USER:\(userId)"
    }
}

// MARK: - QR Code Data Structure
struct QRCodeData: Codable {
    let type: String
    let ticketId: String
    let eventId: String
    let userId: String
    let timestamp: TimeInterval
    let version: String
}

// MARK: - QR Code View Component
struct QRCodeView: View {
    let data: String
    let size: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    @State private var qrImage: UIImage?
    
    init(
        data: String,
        size: CGFloat = 200,
        backgroundColor: Color = .white,
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
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
                size: CGSize(width: size * 3, height: size * 3) // Generate at 3x for crisp display
            )
            
            DispatchQueue.main.async {
                self.qrImage = image
            }
        }
    }
}

// MARK: - Enhanced Ticket QR Code View
struct TicketQRCodeView: View {
    let ticketWithEvent: TicketWithEventData
    @State private var showingFullScreen = false
    @State private var brightness: Double = UIScreen.main.brightness
    
    private var qrCodeData: String {
        guard let ticketId = ticketWithEvent.ticket.id,
              let eventId = ticketWithEvent.event.id else {
            return ticketWithEvent.ticket.qrCode ?? "INVALID_TICKET"
        }
        
        return QRCodeGenerator.generateQRCodeData(
            ticketId: ticketId,
            eventId: eventId,
            userId: ticketWithEvent.ticket.userId
        )
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Your Ticket QR Code")
                .appFont(size: 18, weight: .semibold)
                .foregroundColor(.white)
            
            Button(action: {
                showingFullScreen = true
            }) {
                VStack(spacing: 12) {
                    QRCodeView(
                        data: qrCodeData,
                        size: 200,
                        backgroundColor: .white,
                        foregroundColor: .black
                    )
                    
                    Text(ticketWithEvent.ticket.ticketNumber ?? "No Ticket Number")
                        .appFont(size: 12, weight: .medium)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(spacing: 8) {
                Text("Show this QR code at the venue")
                    .appFont(size: 14)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    showingFullScreen = true
                }) {
                    Text("Tap to enlarge")
                        .appFont(size: 12, weight: .medium)
                        .foregroundColor(.blue)
                }
            }
        }
        .fullScreenCover(isPresented: $showingFullScreen) {
            FullScreenQRCodeView(
                ticketWithEvent: ticketWithEvent,
                qrCodeData: qrCodeData
            )
        }
    }
}

// MARK: - Full Screen QR Code View
struct FullScreenQRCodeView: View {
    let ticketWithEvent: TicketWithEventData
    let qrCodeData: String
    @Environment(\.presentationMode) var presentationMode
    @State private var originalBrightness: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text("Scan at Entry")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("Hold steady for scanning")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // QR Code
                VStack(spacing: 24) {
                    QRCodeView(
                        data: qrCodeData,
                        size: min(UIScreen.main.bounds.width - 80, 300),
                        backgroundColor: .white,
                        foregroundColor: .black
                    )
                    .shadow(color: .black.opacity(0.1), radius: 10)
                    
                    VStack(spacing: 8) {
                        Text(ticketWithEvent.event.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                        
                        Text(ticketWithEvent.ticket.ticketNumber ?? "")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                
                Spacer()
                
                // Event Details
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Date")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                            Text(ticketWithEvent.event.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Venue")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                            Text(ticketWithEvent.event.venue)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Status")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                            Text(ticketWithEvent.ticket.status.capitalized)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 50)
                }
                Spacer()
            }
        }
        .onAppear {
            // Increase brightness for better QR code scanning
            originalBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1.0
        }
        .onDisappear {
            // Restore original brightness
            UIScreen.main.brightness = originalBrightness
        }
    }
}

// MARK: - QR Code Scanner View (for venue staff)
struct QRCodeScannerView: View {
    @State private var isShowingScanner = false
    @State private var scannedTicket: ScannedTicketData?
    @State private var showingResult = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Venue Scanner")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Button(action: {
                isShowingScanner = true
            }) {
                VStack(spacing: 16) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                    
                    Text("Scan Ticket QR Code")
                        .font(.system(size: 18, weight: .semibold))
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
            // QR Scanner implementation would go here
            // You'd need to implement camera-based QR scanning
            Text("QR Scanner Implementation")
                .font(.title)
                .foregroundColor(.white)
        }
        .alert("Scan Result", isPresented: $showingResult) {
            Button("OK") { }
        } message: {
            if let ticket = scannedTicket {
                Text("Ticket: \(ticket.ticketId)\nValid: \(ticket.isValid ? "✅" : "❌")")
            }
        }
    }
}

// MARK: - Supporting Types
struct ScannedTicketData {
    let ticketId: String
    let eventId: String
    let userId: String
    let isValid: Bool
    let scanTime: Date
}

// MARK: - QR Code Validation
struct QRCodeValidator {
    static func validateTicketQRCode(_ qrString: String, for eventId: String) -> Bool {
        // Parse QR code data
        if let data = qrString.data(using: .utf8),
           let qrData = try? JSONDecoder().decode(QRCodeData.self, from: data) {
            
            // Validate structure
            guard qrData.type == "EVENT_TICKET",
                  qrData.eventId == eventId,
                  !qrData.ticketId.isEmpty else {
                return false
            }
            
            // Check timestamp (tickets shouldn't be too old)
            let age = Date().timeIntervalSince1970 - qrData.timestamp
            guard age < 86400 * 30 else { // 30 days max
                return false
            }
            
            return true
        }
        
        // Fallback validation for simple format
        let components = qrString.components(separatedBy: ":")
        return components.count >= 6 &&
               components[0] == "TICKET" &&
               components[2] == "EVENT" &&
               components[3] == eventId
    }
}
