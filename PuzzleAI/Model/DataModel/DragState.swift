//
//  DragState.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import Foundation

enum DragState:Equatable {
    case inactive
    case dragging(translation: CGSize)
}
