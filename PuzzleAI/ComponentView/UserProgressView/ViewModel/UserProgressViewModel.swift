//
//  UserProgressView.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import Foundation

extension UserProgressView {
    struct UserProgressViewModel {
        let unlockPrice:Float = 300
        let unlockText = """
    To unlock the ability to create your own pictures for puzzles with artificial intelligence, you need to complete 10 puzzles in the «Library» tab and have\n500 coins in your balance
    """

        mutating func refillBalance(completion:@escaping(Bool)->()) {
            if DB.db.user?.aiPaid ?? false {
                completion(false)
            } else {
                let price = unlockPrice
                DispatchQueue(label: "db", qos: .userInitiated).async {
                    if DB.db.user?.refillBlance(price * -1) ?? false {
                        DB.db.user?.aiPaid = true
                        DispatchQueue.main.async {
                            completion(true)
                        }
                    }
                }
            }
        }
        
        var isNextEnabled:Bool {
            (DB.db.user?.getBalance.value ?? 0) >= unlockPrice && DB.db.puzzleList.collectedList.count >= PuzzleItem.unlockAiCount
        }
        
        var collectPuzzleProgressText:String {
            "\(DB.db.puzzleList.collectedList.count)/\(PuzzleItem.unlockAiCount)"
        }
    }

}
