
import Foundation
import UIKit
import SwiftUI

struct PuzzleItem:Codable, Equatable {
    static func == (lhs: PuzzleItem, rhs: PuzzleItem) -> Bool {
        lhs.imageName == rhs.imageName && lhs.type == rhs.type && lhs.totalPeaces?.rawValue == rhs.totalPeaces?.rawValue && lhs.completedPeaces == rhs.completedPeaces && lhs.paid == rhs.paid && lhs.bought == rhs.bought && lhs.hints == rhs.hints
    }
    mutating func startOver() {
        hints = 3
        bought = true
        paid = false
        completedPeaces.removeAll()
    }
    
    /// Bundle name or file manager URL
    var imageName:String
    var totalPeaces:Difficulty? = nil
    var type:PuzzleType = .puzzle
    var price:Coint = .init(value: 80)
    var hints:Int = 3
    var paid:Bool = true
    var completedPeaces:[CroppedPuzzleItem] = []
    var bought:Bool = false
    var aIGenerationType:AIGenerationType = .none
    
    func loadImage(quality:ImageQuality = .middle, completion:@escaping(_ image:UIImage?)->()) {
        let manager = FileManagerModel()
        manager.load(imageName: imageName, quality: quality) {
            completion($0)
        }
    }
    
    var isFileURL:Bool {
        imageName.contains("-")
    }
    
    var isCreatedByAI:Bool {
        aIGenerationType != .none
    }

    var reward:Coint {
        return .init(value: (totalPeaces ?? .easy).rewardValue)
    }
    
    var isLocked:Bool {
        paid ? !bought : false
    }
    
    var correctCount:Int {
        completedPeaces.filter({$0.id == $0.draggedID}).count
    }
    
    var isCompleted:Bool {
        progress >= 1
    }
    
    var isClosed:Bool {
        isLocked
    }
    
    /// returns values in range 0..<1
    private var progress:Float {
        if let totalPeaces {
            var results = ((Float(correctCount) * 100) / Float(totalPeaces.piecesCount)) / 100
            if results >= 1 {
                results = 1
            }
            if results <= 0 {
                results = 0
            }
            return results
        } else {
            return 0
        }
    }
    
    var progressInt:Int {
        Int(progress * 100)
    }
    
    var isStarted:Bool {
        return totalPeaces != nil
    }
    
    var completedPeacesCount:Int {
        completedPeaces.filter({$0.draggedID != nil}).count
    }
    
    enum PuzzleType:Codable {
        case square
        case puzzle
    }
    
    static let unlockAiCount = 5
}

extension PuzzleItem {
    enum Difficulty:Int, CaseIterable, Codable {
        ///25// 5,5
        case easy
        ///36// 6,6
        case belowMiddle
        ///49 // 7,7
        case middle
        ///64 // 8,8
        case aboveMiddle
        //81 //9,9
        case belowHard
        //100 //10,10
        case hard
        //144 // 12,12
        case belowHardest
        
        var numberOfRows:Int { i }
        var numberOfSections:Int { i }
        private var i:Int { rawValue + 5 }
        var piecesCount:Int { numberOfRows * numberOfSections }
        
        var rewardValue:Float {
            return switch self {
            case .easy:
                10
            case .belowMiddle:
                20
            case .middle:
                40
            case .aboveMiddle:
                80
            case .belowHard:
                120
            case .hard:
                200
            case .belowHardest:
                260
            }
        }
    }
}

extension [PuzzleItem] {
    static var testData:Self {
        return (1..<25).compactMap({.init(imageName: "test/\($0)", paid: $0 >= 8, aIGenerationType: $0 >= 20 ? .demo : .none)})
    }
    
    mutating func update(item:PuzzleItem, startOver:Bool = false) {
        var new = self
        var newItem = item
        if startOver {
            newItem.totalPeaces = nil
            newItem.hints = 3
            newItem.type = item.type
            newItem.completedPeaces.removeAll()
        }
        for i in 0..<new.count {
            if item.imageName == new[i].imageName {
                new[i] = newItem
            }
        }
        self = new
    }
    
    var collectedList:Self {
        filter({$0.isCompleted})
    }
    
    var aiGeneratedList:Self {
        filter({$0.isCreatedByAI})
    }
    
    mutating func clearGameProgress() {
        var new = self
        for i in 0..<new.count {
            new[i].bought = false
            new[i].completedPeaces.removeAll()
            new[i].paid = i >= 5
        }
        self = new
    }
}


struct CroppedPuzzleItem:Codable, Equatable {
    let id:Int
    var draggedID:Int? = nil
    var image:UIImage?
    var ignoreSides:[PuzzleMaskModel.IgnoreSide]
    
    var isCornered:Bool {
        if ignoreSides.isEmpty {
            return false
        }
        return ignoreSides.count != 4
    }
    
    enum CodingKeys: CodingKey {
        case id
        case draggedID
        case ignoreSides
    }
}

extension [CroppedPuzzleItem] {
    mutating func removeImages() {
        self = self.compactMap({
            var new = $0
            new.image = nil
            return new
        })
    }
    
    func isCompleted() -> Bool {
        if self.count == 0 {
            return false
        }
        let completed = !self.contains(where: {$0.draggedID == nil || $0.draggedID != $0.id})
        return completed
    }
}

enum AIGenerationType:Codable {
    /// Puzzle item from xasset
    case demo
    case byUser
    case none
}
