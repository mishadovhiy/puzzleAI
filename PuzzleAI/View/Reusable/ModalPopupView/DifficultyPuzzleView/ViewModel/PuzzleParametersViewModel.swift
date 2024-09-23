
import Foundation
import SwiftUI

struct DifficultyPuzzleViewModel {
    var toStartOverPressed:((_ newPuzzle:PuzzleItem?)->())?
    var selectedDifficulty:PuzzleItem.Difficulty = .easy
    var selectedPuzzleType:PuzzleItem.PuzzleType = .puzzle
    var puzzle:PuzzleItem = .init(imageName: "-")
    var stopButtonAnimations:Bool = false
    var targetIndex: Int? = nil
    
    var nextEnabled:Bool {
        if puzzle.isLocked && !puzzle.bought {
            return DB.db.user?.getBalance.value ?? 0 >= puzzle.price.value
        } else {
            return true
        }
    }
    
    var peacesCount:[Int] = PuzzleItem.Difficulty.allCases.compactMap {
        $0.piecesCount
    }
    
    func startOverPressed() {
        self.performToStartOver()
    }
    
    private func performToStartOver(puzzle:PuzzleItem? = nil) {
        DispatchQueue(label: "db", qos: .userInitiated).async {
            var puzzle = puzzle ?? self.puzzle
            puzzle.totalPeaces = selectedDifficulty
            puzzle.type = selectedPuzzleType
            puzzle.hints = 3
            puzzle.completedPeaces.removeAll()
            DB.db.puzzleList.update(item: puzzle, startOver: false)
            DispatchQueue.main.async {
                toStartOverPressed?(puzzle)
            }
        }
    }
    
    func difficultyCellSize(itemID:Int) -> CGSize {
        let scale = selectedDifficulty.rawValue == itemID ? 1.5 : 1
        let normalSize:Double = selectedPuzzleType == .puzzle ? 80 : 50
        let width = normalSize * scale
        return .init(width: width, height: width)
    }
    
    mutating func scrollOffsetChanged(_ offsetX: CGFloat) {
        let totalSize = viewTotalWidth
        var i = (offsetX / totalSize)
        if i >= 0 {
            i = 0
        }
        if i <= -1 {
            i = -1
        }
        let selectedDifficulty = Int(round(i * CGFloat(PuzzleItem.Difficulty.allCases.count * -1))) - 1
        if self.selectedDifficulty.rawValue != selectedDifficulty {
            withAnimation {
                self.selectedDifficulty = .init(rawValue: selectedDifficulty) ?? .easy
            }
        }
    }
        
    var viewTotalWidth:CGFloat {
        let count = CGFloat(PuzzleItem.Difficulty.allCases.count)
        return difficultyCellSize(itemID: -1).width * count
    }
}

extension DifficultyPuzzleViewModel {
    func countImageColor(_ itemID:Int) -> Color {
        selectedDifficulty.rawValue == itemID ? .blueTint : .descriptionText
    }
    
    func countTextColor(_ itemID:Int) -> Color {
        selectedDifficulty.rawValue == itemID ? .title : .generalBackground
    }
    
    func typeTextColor(_ isSquare:Bool) -> Color {
        selectedPuzzleType == .square && isSquare || !isSquare && selectedPuzzleType == .puzzle ? .blueTint : .descriptionText
    }
}
