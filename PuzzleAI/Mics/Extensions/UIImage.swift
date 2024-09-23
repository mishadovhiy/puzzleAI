
import UIKit

extension UIImage {
    convenience init?(name:String) {
        if name.contains("-") || name.isEmpty {
            return nil
        }
        self.init(named: name)
    }

    func changeSize(newWidth:CGFloat, from:CGSize? = nil, origin:CGPoint = .zero) -> UIImage {
#if os(iOS)
        let widthPercent = newWidth / (from?.width ?? self.size.width)
        let proportionalSize: CGSize = .init(width: newWidth, height: widthPercent * (from?.height ?? self.size.height))
        let renderer = UIGraphicsImageRenderer(size: proportionalSize)
        let newImage = renderer.image { _ in
            self.draw(in: CGRect(origin: origin, size: proportionalSize))
        }
        return newImage
#else
        return self
#endif

    }
    func changeSize2() -> UIImage? {
        let targetSize = CGSize(width: 20, height: 20)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        self.draw(in: CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    func cropped(to rect: CGRect) -> UIImage? {
        let scale = self.scale
        let scaledRect = CGRect(x: rect.origin.x * scale,
                                y: rect.origin.y * scale,
                                width: rect.size.width * scale,
                                height: rect.size.height * scale)
        
        guard let imageRef = self.cgImage?.cropping(to: scaledRect) else {
            return nil
        }
        
        let croppedImage = UIImage(cgImage: imageRef, scale: scale, orientation: self.imageOrientation)
        
        return croppedImage
    }
    
    func cropImage(toRect cropRect: CGRect) -> UIImage? {
        guard let cgImage = self.cgImage else {
            return nil
        }
        
        let scaledCropRect = CGRect(
            x: cropRect.origin.x * self.scale,
            y: cropRect.origin.y * self.scale,
            width: cropRect.size.width * self.scale,
            height: cropRect.size.height * self.scale
        )
        
        guard let croppedCgImage = cgImage.cropping(to: scaledCropRect) else {
            return nil
        }
        
        let croppedImage = UIImage(cgImage: croppedCgImage, scale: self.scale, orientation: self.imageOrientation)
        
        return croppedImage
    }
}
