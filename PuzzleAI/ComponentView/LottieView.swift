
#if os(iOS)
import Lottie
import SwiftUI

struct LottieView: UIViewRepresentable {
    let loopMode: LottieLoopMode
    let name:LottieType
    
    func updateUIView(_ uiView: UIViewType, context: Context) { }
    
    func makeUIView(context: Context) -> Lottie.LottieAnimationView {
        let animationView = LottieAnimationView(name: name.rawValue)
        animationView.play()
        animationView.loopMode = loopMode
        animationView.contentMode = .scaleAspectFit
        return animationView
    }
    
    enum LottieType:String {
        case primaryLoader, longPress, aiGeneration, noPuzzleList
    }
}
#else
struct LottieView {
    enum LottieType:String {
        case primaryLoader, longPress, aiGeneration, noPuzzleList
    }
}
#endif
