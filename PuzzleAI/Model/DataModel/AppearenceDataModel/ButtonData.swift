//
//  ButtonData.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import Foundation

struct ButtonData {
    var title:String
    var type:Style = .primary
    var pressed:(()->())?
    
    enum Style {
        case primary
        case secondary
    }
}
