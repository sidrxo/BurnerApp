import SwiftUI
import CoreImage.CIFilterBuiltins


struct QRCodeData: Codable {
    let type: String
    let ticketId: String
    let eventId: String
    let userId: String
    let ticketNumber: String?
    let timestamp: TimeInterval
    let version: String
    let hash: String
}

struct ScannedTicketData {
    let ticketId: String
    let eventId: String
    let userId: String
    let isValid: Bool
    let scanTime: Date
}


struct QRCodeGenerator {

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


}

struct QRCodeValidator {

    static func validateTicketQRCode(_ qrString: String, for eventId: String) -> Bool {
        // Parse QR code data
        guard let data = qrString.data(using: .utf8),
              let qrData = try? JSONDecoder().decode(QRCodeData.self, from: data) else {
            return false
        }

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
}

// MARK: - Basic QR Code View
struct QRCodeView: View {
    let data: String
    let size: CGFloat
    @State private var qrImage: UIImage?
    
    init(data: String, size: CGFloat = 200) {
        self.data = data
        self.size = size
    }
    
    var body: some View {
        Group {
            if let qrImage = qrImage {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: size, height: size)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: size, height: size)
                    .overlay(
                        VStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Generating QR...")
                                .font(.caption)
                                .foregroundColor(.gray)
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
