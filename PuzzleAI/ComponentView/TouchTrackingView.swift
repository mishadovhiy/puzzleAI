
import SwiftUI
#if os(iOS)
class TouchTrackingUIView: UIView {
    var onTouch: ((_ began:Bool) -> Void)?
    var onTouchMoved: (() -> Void)?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        onTouch?(true)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        onTouch?(true)
        onTouchMoved?()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        onTouch?(false)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        onTouch?(false)
    }
}

struct TouchTrackingView: UIViewRepresentable {
    var onTouch: (_ began:Bool) -> Void
    var onTouchMoved: () -> Void

    func makeUIView(context: Context) -> TouchTrackingUIView {
        let view = TouchTrackingUIView()
        view.onTouch = onTouch
        view.onTouchMoved = onTouchMoved
        return view
    }

    func updateUIView(_ uiView: TouchTrackingUIView, context: Context) { }
}

#endif
