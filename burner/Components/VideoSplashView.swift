//
//  VideoSplashView.swift
//  burner
//
//  Created by Sid Rao on 06/11/2025.
//


import SwiftUI
import AVFoundation
import AVKit

/// A simple SwiftUI wrapper that plays a local MP4 from the app bundle.
/// - `videoName`: filename without extension (e.g. "splash")
/// - `loop`: whether to loop the video (AVQueuePlayer + AVPlayerLooper)
/// - `onFinished`: called when the video completes (only called if loop == false)
struct VideoSplashView: View {
    let videoName: String
    var loop: Bool = false
    var onFinished: (() -> Void)?

    var body: some View {
        VideoPlayerUIView(
            url: Bundle.main.url(forResource: videoName, withExtension: "mp4"),
            loop: loop,
            onFinish: onFinished
        )
        .scaleEffect(x: 1.0, y: 0.9)
        .background(Color.black)
        .ignoresSafeArea()
    }
}

private struct VideoPlayerUIView: UIViewRepresentable {
    let url: URL?
    let loop: Bool
    let onFinish: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: .zero)
        container.backgroundColor = .black

        guard let url = url else { return container }

        // Configure audio session so the video doesn't abruptly stop other audio unless you want it to.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true, options: [])

        if loop {
            // Use AVQueuePlayer + AVPlayerLooper for seamless looping
            let player = AVQueuePlayer()
            let item = AVPlayerItem(url: url)
            let looper = AVPlayerLooper(player: player, templateItem: item)

            let layer = AVPlayerLayer(player: player)
            layer.videoGravity = .resizeAspectFill
            layer.frame = container.bounds
            layer.needsDisplayOnBoundsChange = true
            container.layer.addSublayer(layer)

            context.coordinator.store(player: player, layer: layer, looper: looper, container: container)
            player.play()
        } else {
            let player = AVPlayer(url: url)
            let layer = AVPlayerLayer(player: player)
            layer.videoGravity = .resizeAspectFill
            layer.frame = container.bounds
            layer.needsDisplayOnBoundsChange = true
            container.layer.addSublayer(layer)

            // Observe end-of-playback
            context.coordinator.registerEndObserver(for: player.currentItem)
            context.coordinator.store(player: player, layer: layer, looper: nil, container: container)
            player.play()
        }

        // Ensure layer resizes with container
        context.coordinator.onLayout = { newBounds in
            context.coordinator.playerLayer?.frame = newBounds
            context.coordinator.fadeOverlay?.frame = newBounds
        }

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update layer frames if the view size changed
        context.coordinator.onLayout?(uiView.bounds)
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.cleanup()
    }

    final class Coordinator {
        private(set) var player: AVPlayer?
        var playerLayer: AVPlayerLayer?
        var looper: AVPlayerLooper?
        var onFinish: (() -> Void)?
        var endObserver: Any?
        var onLayout: ((CGRect) -> Void)?
        var pauseTimer: Timer?
        var fadeOverlay: CALayer?
        weak var containerView: UIView?

        init(onFinish: (() -> Void)?) {
            self.onFinish = onFinish
        }

        func store(player: AVPlayer, layer: AVPlayerLayer, looper: AVPlayerLooper?, container: UIView) {
            self.player = player
            self.playerLayer = layer
            self.looper = looper
            self.containerView = container
        }

        func registerEndObserver(for item: AVPlayerItem?) {
            guard let item = item else { return }
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                // Pause on the end frame and fade to black over 2 seconds
                DispatchQueue.main.async {
                    self?.player?.pause()
                    self?.addFadeToBlack()
                    self?.pauseTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                        self?.onFinish?()
                    }
                }
            }
        }

        private func addFadeToBlack() {
            guard let container = containerView else { return }
            
            // Create a black overlay layer
            let overlay = CALayer()
            overlay.frame = container.bounds
            overlay.backgroundColor = UIColor.black.cgColor
            overlay.opacity = 0.0
            container.layer.addSublayer(overlay)
            self.fadeOverlay = overlay
            
            // Animate opacity from 0 to 1 over 2 seconds
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = 0.0
            animation.toValue = 1.0
            animation.duration = 0.5
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            
            overlay.add(animation, forKey: "fadeToBlack")
            overlay.opacity = 1.0 // Set final state
        }

        func cleanup() {
            pauseTimer?.invalidate()
            pauseTimer = nil
            
            fadeOverlay?.removeFromSuperlayer()
            fadeOverlay = nil
            
            if let observer = endObserver {
                NotificationCenter.default.removeObserver(observer)
                endObserver = nil
            }
            player?.pause()
            player = nil
            looper = nil
            playerLayer?.removeFromSuperlayer()
            playerLayer = nil
            // deactivate audio session if you set it active here (optional)
            try? AVAudioSession.sharedInstance().setActive(false)
        }
    }
}
