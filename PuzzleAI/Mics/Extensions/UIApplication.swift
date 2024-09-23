
import UIKit

extension UIApplication {
    var keyWindow:UIWindow? {
        let scene = self.connectedScenes.first(where: {
            let window = $0 as? UIWindowScene
            return window?.activationState == .foregroundActive && (window?.windows.contains(where: { $0.isKeyWindow}) ?? false)
        }) as? UIWindowScene
        return scene?.windows.last(where: {$0.isKeyWindow }) ?? ((self.connectedScenes.first as? UIWindowScene)?.windows.first)
    }
}
