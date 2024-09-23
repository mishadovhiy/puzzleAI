
import Foundation

struct PuzzlePopupViewModel {
    var parentData:ModalPopupViewModel.ModalPopupData = .init()
    var isStartOverAlertPresenting:Bool = false
    var stopButtonAnimations:Bool = false
    var dataUpdated:((_ newData:ModalPopupViewModel.ModalPopupData)->())?
    var toDifficultyAction:(()->())?
    var loadingButtonReloadID:UUID = .init()
    
    func toStartOverConfirmed(puzzle:PuzzleItem? = nil) {
        var new = parentData
        new.puzzle = nil
        new.difficulty = puzzle ?? self.puzzle
        dataUpdated?(new)
    }
    
    private mutating func performStartOver() {
        var new = self.puzzle
        new.startOver()

        for i in 0..<DB.db.puzzleList.count {
            if DB.db.puzzleList[i].imageName == new.imageName {
                DB.db.puzzleList[i] = new
            }
        }
        self.performToStartOver(new)
    }
    
    mutating func toStartOver() {
        if puzzle.isLocked {
            if DB.db.user?.refillBlance(puzzle.price.value * -1) ?? false {
                performStartOver()
            }
        } else {
            performStartOver()
        }
        
    }
    
    mutating private func performToStartOver(_ puzzle:PuzzleItem? = nil) {
        let puzzle = puzzle ?? self.puzzle
        if puzzle.isStarted {
            self.isStartOverAlertPresenting = true
        } else {
            toStartOverConfirmed(puzzle:puzzle)
        }
    }
    
    mutating func todifficulty() {
        if puzzle.isStarted {
            toDifficultyAction?()
        } else {
            toStartOver()
        }
    }
    
    var puzzle:PuzzleItem {
        return parentData.puzzle ?? .init(imageName: "")
    }
    
    var coint:Coint {
        puzzle.isLocked ? puzzle.price : puzzle.reward
    }
    
    var cointTitle:String {
        puzzle.isLocked ? "Price:" : "Reward:"
    }
    
    var primaryButtonTitle:String {
        puzzle.isStarted ? "Continue" : getPuzzleButtonTitle
    }
    let secondaryButtonTitle = "Start over"

    
    var alertDescription:String {
        "If you start solving the puzzle again, the current progress will be lost."
    }
    
    var nextEnabled:Bool {
        if puzzle.isLocked && !puzzle.bought {
            return DB.db.user?.getBalance.value ?? 0 >= puzzle.price.value
        } else {
            return true
        }
    }
    
    var getPuzzleButtonTitle:String {
        nextEnabled ? "Get Puzzle" : "Not enough funds"
    }
}
