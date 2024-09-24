//
//  String.swift
//  PuzzleAI
//
//  Created by Mykhailo Dovhyi on 24.09.2024.
//
//  String.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import Foundation

extension String {
    var numbers:Int {
        let pattern = "\\d+"
        let regex = try! NSRegularExpression(pattern: pattern)
        let nsString = self as NSString
        let results = regex.matches(in: self, range: NSRange(location: 0, length: nsString.length))
        
        let array = results.compactMap { Int(nsString.substring(with: $0.range)) }
        return Int(array.compactMap({"\($0)"}).joined(separator: "")) ?? 0
    }
}
