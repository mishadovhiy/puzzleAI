//
//  CointListItem.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import Foundation

struct CointListItem:Equatable {
    static func == (lhs: CointListItem, rhs: CointListItem) -> Bool {
        lhs.title == rhs.title && lhs.price.value == rhs.price.value
    }
    
    let title:String
    var price:Coint
}

extension CointView {
    static var priceStartAmount:Float { 200 }
    static var priceMultiplyAmount:Int{ 50 }
}

extension [CointListItem] {
    static func cointList(title:String, titleFirst:Bool = false) -> Self {
        (0..<7).compactMap({
            var titleResylt = "\($0 + 1)"
            if titleFirst {
                titleResylt = title + " " + titleResylt
            } else {
                titleResylt.append(" " + title)
            }
            let priceValue = CointView.priceStartAmount + Float(CointView.priceMultiplyAmount * $0)
            return .init(title: titleResylt, price: .init(value: priceValue))
        })
    }
}
