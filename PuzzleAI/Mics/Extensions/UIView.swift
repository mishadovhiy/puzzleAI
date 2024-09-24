//
//  UIView.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import UIKit
#if os(iOS)
extension UIView {
    func convertedToImage(bounds:CGRect? = nil) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: bounds ?? self.bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
#endif
