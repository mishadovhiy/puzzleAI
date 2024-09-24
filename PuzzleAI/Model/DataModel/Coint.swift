//
//  Coint.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import Foundation

struct Coint:Codable, Equatable {
    static func == (lhs: Coint, rhs: Coint) -> Bool {
        lhs.value == rhs.value && lhs.type.rawValue == rhs.type.rawValue
    }
    var type:Type = .default
    var value:Float
    var id:String = UUID().uuidString
    
    enum `Type`:String, Codable {
        case `default` = "coint"
        
        var imageName:String {
            return rawValue
        }
    }
    
    var stringValue:String {
        "\(Int(value))"
    }
}
