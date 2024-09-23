
import UIKit
import SwiftUI

extension UINavigationController: UIGestureRecognizerDelegate {
    
    static var canSetSwipeGesture = true
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return UINavigationController.canSetSwipeGesture ? viewControllers.count > 1 : false
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        UINavigationController.canSetSwipeGesture ? true : false
    }
}
