//
//  Int.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import Foundation

extension Int {
    func index(_ section:Int, numberOfRows:Int) -> Self {
        (self + 1) + (section * numberOfRows) - 1
    }
}
