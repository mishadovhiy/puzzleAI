
import UIKit

struct PuzzleCompletionViewModel {
    var isSharePressed:Bool = false
    var puzzle:PuzzleItem = .init(imageName: "")
    
    var userBalance:Coint {
        DB.db.user?.getBalance ?? .init(value: 0)
    }
    
    mutating func sharePressed() {
        isSharePressed = true
    }
    
    func startOverPressed(completed:@escaping(PuzzleItem)->()) {
        Task {
            DB.db.puzzleList.update(item: puzzle, startOver: true)
            await MainActor.run {
                completed(DB.db.puzzleList.first(where: {$0.imageName == puzzle.imageName}) ?? .init(imageName: puzzle.imageName))
            }
        }
    }
}
