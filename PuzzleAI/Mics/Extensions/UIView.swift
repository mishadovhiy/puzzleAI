
import UIKit

extension UIView {
    func convertedToImage(bounds:CGRect? = nil) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: bounds ?? self.bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
