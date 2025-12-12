import SwiftUI
import AVFoundation
import AVKit

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
        // REMOVED: .scaleEffect(x: 0.8, y: 0.8) to make it edge-to-edge
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

        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true, options: [])

        if loop {
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

            context.coordinator.registerEndObserver(for: player.currentItem)
            context.coordinator.store(player: player, layer: layer, looper: nil, container: container)
            player.play()
        }

        context.coordinator.onLayout = { newBounds in
            context.coordinator.playerLayer?.frame = newBounds
        }

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
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
                // Directly call finish — no fading
                self?.onFinish?()
            }
        }

        func cleanup() {
            if let observer = endObserver {
                NotificationCenter.default.removeObserver(observer)
                endObserver = nil
            }
            player?.pause()
            player = nil
            looper = nil
            playerLayer?.removeFromSuperlayer()
            playerLayer = nil

            try? AVAudioSession.sharedInstance().setActive(false)
        }
    }
}
