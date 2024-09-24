//
//  PuzzleMaskModel.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import SwiftUI

/// Generates puzzle shape item from UIImage
struct PuzzleMaskModel {
    enum CropInsideType {
        /// oval position inside rectengle:
        /// - left and right corners - inside, top and bottom - outside
        case horizontally
        /// oval position inside rectengle:
        /// top and bottom corners - inside, left and right - outside
        case verticaly
        
        init(_ index:Int) {
            self = (index % 2) == 0 ? .horizontally : .verticaly
        }
    }
    
    static func puzzleImage(originalImage:UIImage, itemSize:CGSize, totalSize:CGSize, offset:CGPoint, exept:[IgnoreSide], inside:CropInsideType) -> UIImage? {
        let properties = ResultProperties(itemSize: itemSize, offset: offset, inside: inside, exept: exept)
        
        let path = UIBezierPath()
        let unionAt = 0.5
        path.move(to: properties.topLeftCorner)
        
        if !exept.contains(.top) {
            if inside == .horizontally {
                path.addArc(withCenter: properties.topMiddle, 
                            radius: properties.margin / 2,
                            startAngle: unionAt,
                            endAngle: .pi - unionAt,
                            clockwise: false)
            } else {
                path.addArc(withCenter: properties.topMiddle, 
                            radius: properties.margin / 2,
                            startAngle: .pi + unionAt,
                            endAngle: (3 * .pi / 2) + (unionAt * 2),
                            clockwise: false)
            }
        }
        path.addLine(to: properties.topRightCorner)
        
        if !exept.contains(.right) {
            if inside == .horizontally {
                path.addArc(withCenter: properties.rightMiddle, 
                            radius: properties.margin / 2,
                            startAngle:  (3 * .pi / 2) + unionAt,
                            endAngle: (.pi / 2) - unionAt,
                            clockwise: false)
            } else {
                path.addArc(withCenter: properties.rightMiddle, 
                            radius: properties.margin / 2,
                            startAngle: (.pi / 2) + unionAt,
                            endAngle: (3 * .pi / 2) - unionAt,
                            clockwise: false)
            }
        }
        path.addLine(to: properties.bottomRightCorner)
        
        if !exept.contains(.bottom) {
            if inside == .horizontally {
                path.addArc(withCenter: properties.bottomMiddle,
                            radius: properties.margin / 2,
                            startAngle: -unionAt, endAngle: .pi + unionAt, 
                            clockwise: true)
            } else {
                path.addArc(withCenter: properties.bottomMiddle, 
                            radius: properties.margin / 2,
                            startAngle: unionAt,
                            endAngle: .pi - unionAt, clockwise: false)
            }
        }
        path.addLine(to: properties.bottomLeftCorner)
        
        if !exept.contains(.left) {
            if inside == .horizontally {
                path.addArc(withCenter: properties.leftMiddle, 
                            radius: properties.margin / 2,
                            startAngle: (.pi / 2) + unionAt, 
                            endAngle: (3 * .pi / 2) - unionAt,
                            clockwise: false)
            } else {
                path.addArc(withCenter: properties.leftMiddle, 
                            radius: properties.margin / 2,
                            startAngle: (.pi / 2) - unionAt,
                            endAngle: (3 * .pi / 2) + unionAt,
                            clockwise: true)
            }
        }
        
        path.addLine(to: properties.topLeftCorner)
        path.lineCapStyle = .round
        path.addClip()
        path.lineJoinStyle = .round
        path.close()
        
        let layer = CAShapeLayer()
        layer.path = path.cgPath
        layer.fillColor = UIColor.red.cgColor
        
        let view = UIImageView(image: originalImage)
        view.frame = CGRect(origin: .zero, size: totalSize)
        view.center = view.center
        view.layer.mask = layer
        let newImage = view.convertedToImage()
        let resultFrame:CGRect = .init(origin: offset, size: itemSize)
        return newImage?.cropImage(toRect: resultFrame)?.changeSize(newWidth: totalSize.width)
    }
    
    // MARK: - data model
    enum IgnoreSide:Codable {
        case left, right, top, bottom
    }
}

fileprivate extension PuzzleMaskModel {
    struct ResultProperties {
        private let width:CGFloat
        private let height:CGFloat
        let margin:CGFloat
        let additionalOutsideSpace:CGFloat
        
        let topLeftCorner:CGPoint
        let topMiddle:CGPoint
        let topRightCorner:CGPoint
        let rightMiddle:CGPoint
        let bottomRightCorner:CGPoint
        let bottomMiddle:CGPoint
        let bottomLeftCorner:CGPoint
        let leftMiddle:CGPoint
        
        init(itemSize:CGSize, offset:CGPoint, inside:CropInsideType, exept:[IgnoreSide]) {
            self.width = itemSize.width
            self.height = itemSize.height
            self.margin = CollectPuzzleView.ViewModel.margin(itemWidth: width)
            self.additionalOutsideSpace = (margin / 2)
            let gap = MarginGapModel(exept: exept, defaultMargin: margin)

            let topX = (width / 2.0 + offset.x) + ((exept.contains(.left) || exept.contains(.right)) ? (additionalOutsideSpace * (exept.contains(.left) ? -1 : 1)) : 0)
            let leftY = (exept.contains(.top) || exept.contains(.bottom)) ? (additionalOutsideSpace * (exept.contains(.bottom) ? 1 : -1)) : 0
            
            let smallMargin = additionalOutsideSpace / 2
            let bigMargin = additionalOutsideSpace * 1.5

            let ovalFrame:CGRect = .init(x: offset.x,
                                        y: height / 2.0 + offset.y,
                                        width: width + offset.x, 
                                         height: height + offset.y)
            
            if inside == .horizontally {
                topMiddle = CGPoint(x: topX, y: offset.y + gap.val(.top, bigMargin))
                bottomMiddle = CGPoint(x: topMiddle.x,  y: ovalFrame.height - gap.val(.bottom, bigMargin))
                leftMiddle = CGPoint(x: offset.x + gap.val(.left, margin + smallMargin), y: ovalFrame.minY + leftY)
                rightMiddle = CGPoint(x: ovalFrame.width - gap.val(.right, margin + smallMargin), y: leftMiddle.y)
                
                topLeftCorner = CGPoint(x: offset.x + gap.val(.left, margin), y: offset.y + gap.val(.top))
                bottomLeftCorner = CGPoint(x: topLeftCorner.x, y: ovalFrame.height - gap.val(.bottom))
                topRightCorner = CGPoint(x: ovalFrame.width - gap.val(.right), y: topLeftCorner.y)
                bottomRightCorner = CGPoint(x: topRightCorner.x, y: bottomLeftCorner.y)

            } else {
                topMiddle = CGPoint(x: topX, y: offset.y + gap.val(.top, margin + smallMargin))
                bottomMiddle = CGPoint(x: topMiddle.x, y: ovalFrame.height - gap.val(.bottom, margin + smallMargin))
                leftMiddle = CGPoint(x: offset.x + gap.val(.left, bigMargin), y: ovalFrame.minY + leftY)
                rightMiddle = CGPoint(x: ovalFrame.width - gap.val(.right, bigMargin), y: leftMiddle.y)
                
                topLeftCorner = CGPoint(x: offset.x + gap.val(.left),
                                        y: offset.y + gap.val(.top))
                bottomLeftCorner = CGPoint(x: topLeftCorner.x, y: ovalFrame.height - gap.val(.bottom))
                topRightCorner = CGPoint(x: ovalFrame.width - gap.val(.right), y: topLeftCorner.y)
                bottomRightCorner = CGPoint(x: topRightCorner.x, y: bottomLeftCorner.y)
            }
        }
    }
}

extension PuzzleMaskModel {
    struct MarginGapModel {
        private let exept:[IgnoreSide]
        private let defaultMargin:CGFloat
        
        init(exept:[IgnoreSide], defaultMargin:CGFloat) {
            self.exept = exept
            self.defaultMargin = defaultMargin
        }
        
        func val(_ side:IgnoreSide,
                   _ margin:CGFloat? = nil) -> CGFloat {
            exept.contains(side) ? 0 : (margin ?? defaultMargin)
        }
    }
}
