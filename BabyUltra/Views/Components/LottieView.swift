import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    let name: String
    var loopMode: LottieLoopMode = .loop

    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView()

        // Try loading from bundle root first, then from Resources subdirectory
        if let animation = LottieAnimation.named(name, bundle: Bundle.main, subdirectory: nil) {
            animationView.animation = animation
        } else if let path = Bundle.main.path(forResource: name, ofType: "json", inDirectory: "Resources"),
                  let animation = LottieAnimation.filepath(path) {
            animationView.animation = animation
        }

        animationView.loopMode = loopMode
        animationView.contentMode = .scaleAspectFit
        animationView.clipsToBounds = true
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.play()
        return animationView
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {}
}
