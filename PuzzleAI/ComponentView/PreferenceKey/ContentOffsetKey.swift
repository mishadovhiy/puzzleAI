//
//  ContentOffsetKey.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import SwiftUI

struct ContentOffsetKey: PreferenceKey {
    typealias Value = CGRect
    static var defaultValue = CGRect.zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        value = .init(x: next.minX + value.minX, y: next.minY + value.minY, width: value.width, height: value.height)
    }
}
