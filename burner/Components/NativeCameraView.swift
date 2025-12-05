import SwiftUI
import AVFoundation

// ALTERNATIVE SOLUTION: Native AVFoundation Camera View
// If CodeScanner isn't working, use this instead

struct NativeCameraView: UIViewControllerRepresentable {
    let completion: (Result<String, Error>) -> Void
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.completion = completion
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

class CameraViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var completion: ((Result<String, Error>) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    private func setupCamera() {
        print("🎥 [NATIVE CAMERA] Setting up camera...")
        
        captureSession = AVCaptureSession()
        
        guard let captureSession = captureSession else {
            print("🎥 [NATIVE CAMERA] ❌ Failed to create capture session")
            return
        }
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("🎥 [NATIVE CAMERA] ❌ No video capture device available")
            completion?(.failure(NSError(domain: "Camera", code: -1, userInfo: [NSLocalizedDescriptionKey: "No camera available"])))
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
                print("🎥 [NATIVE CAMERA] ✓ Video input added")
            } else {
                print("🎥 [NATIVE CAMERA] ❌ Cannot add video input")
                completion?(.failure(NSError(domain: "Camera", code: -2, userInfo: [NSLocalizedDescriptionKey: "Cannot add video input"])))
                return
            }
            
            let metadataOutput = AVCaptureMetadataOutput()
            
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
                print("🎥 [NATIVE CAMERA] ✓ Metadata output added")
            } else {
                print("🎥 [NATIVE CAMERA] ❌ Cannot add metadata output")
                completion?(.failure(NSError(domain: "Camera", code: -3, userInfo: [NSLocalizedDescriptionKey: "Cannot add metadata output"])))
                return
            }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.frame = view.bounds
            previewLayer?.videoGravity = .resizeAspectFill
            
            if let previewLayer = previewLayer {
                view.layer.addSublayer(previewLayer)
                print("🎥 [NATIVE CAMERA] ✓ Preview layer added")
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.startRunning()
                print("🎥 [NATIVE CAMERA] ✓ Capture session started")
            }
            
        } catch {
            print("🎥 [NATIVE CAMERA] ❌ Error setting up camera: \(error.localizedDescription)")
            completion?(.failure(error))
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession?.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            print("🎥 [NATIVE CAMERA] ✓ QR Code detected: \(stringValue)")
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            completion?(.success(stringValue))
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if captureSession?.isRunning == true {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.stopRunning()
            }
        }
    }
}

// USAGE IN YOUR SCANNER VIEW:
// Replace CodeScannerView with:
/*
NativeCameraView { result in
    switch result {
    case .success(let code):
        validateAndScanTicket(qrCodeData: code)
    case .failure(let error):
        errorMessage = "Scanning failed: \(error.localizedDescription)"
        showingError = true
    }
}
.ignoresSafeArea()
*/