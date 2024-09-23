
import Foundation
import Combine
import UIKit

struct DB {
    static private let dbName:String = "DataBase48"
    static var db:DataBase {
        get {
            if let dbHolder {
                return dbHolder
            }
#if DEBUG
            if Thread.isMainThread {
                print("threadError\n", #file, "\n", #line)
            }
#endif
            let value = DataBase.configure(UserDefaults.standard.data(forKey: dbName)) ?? .init()
            return value
        }
        set {
            if Thread.isMainThread {
                Task(priority:.high) {
                    updateDB(newValue)
                }
            } else {
                updateDB(newValue)
            }
        }
    }
    
    private static func saveDemoImages(data:[PuzzleItem], completion:@escaping()->()) {
        let manager = FileManagerModel()
        let stringData = data.compactMap({$0.imageName})
        let count = stringData.count
        let aiIndex = data.firstIndex(where: {$0.isCreatedByAI}) ?? 0
        let lockedIndex = data.firstIndex(where: {$0.isLocked}) ?? 0

        manager.saveImageList(stringData, startsAiFrom: count - aiIndex, paidIndex: count - lockedIndex) {
            completion()
        }
    }
    
    static func configure(completion:@escaping()->(), clearPressed:Bool = false) {
        Task(priority: .high) {
            let data = db
            dbHolder = data
            if data.puzzleList.isEmpty {
                self.saveDemoImages(data: .testData) {
                    db.user = .init()
                    Task {
                        await MainActor.run {
                            completion()
                        }
                    }
                }
                
            } else {
                await MainActor.run {
                    completion()
                }
            }
            
        }
    }
    
    static func clearDataBase(completion:@escaping()->()) {
        DB.db.user = .init()
        DB.db.rewardList.removeAll()
        DB.db.lastLogin = .init()
        configure(completion: completion, clearPressed: true)
    }
    
    static private func updateDB(_ newValue:DataBase) {
        dbHolder = newValue
        if !tempHolderList.isEmpty {
            let holder = tempHolderList
            DispatchQueue.main.async {
                DB.puzzlePublisher.publisher.send(holder)
            }
            tempHolderList.removeAll()
            
        }
        if let data = newValue.decode {
            UserDefaults.standard.setValue(data, forKey: dbName)
        } else {
            UserDefaults.standard.removeObject(forKey: dbName)
        }
    }
    
    static var dbHolder:DataBase?
    
    struct UserSubscriber {
        var publisher = PassthroughSubject<User?, Never>()
        var cancellable: AnyCancellable?
    }
    struct ListSubscriber {
        var publisher = PassthroughSubject<[PuzzleItem]?, Never>()
        var cancellable: AnyCancellable?
    }
    static var tempHolderList:[PuzzleItem] = []
    static var puzzlePublisher: ListSubscriber = .init()
    static var userPublisher: UserSubscriber = .init()
}

struct DataBase:Codable {
    var lastLogin:LastLoginRowData? = nil
    var user:User? = nil {
        didSet {
            if Thread.isMainThread {
                DB.userPublisher.publisher.send(user)
            } else {
                let value = user
                DispatchQueue.main.async {
                    DB.userPublisher.publisher.send(value)
                }
            }
        }
    }
    
    var errorTokenValue:String = ""
    
    private var _tutorialValue:Tutorial = .init()
    var tutorials:Tutorial {
        get { _tutorialValue }
        set {
            _tutorialValue = newValue
        }
    }
    
    
    var puzzleList:[PuzzleItem] = [] {
        didSet {
            DB.tempHolderList = puzzleList
        }
    }
    
    mutating func puzzleCompleted(puzzle:PuzzleItem) {
        puzzleCompletionShowed.append(puzzle)
        let _ = user?.refillBlance(puzzle.reward.value)
    }
    
    var puzzleCompletionShowed:[PuzzleItem] = []
    var rewardList:[Reward] = []
    
    func isCompletionShowed(for item:PuzzleItem) -> Bool {
        puzzleCompletionShowed.contains(where: {
            $0.imageName == item.imageName && $0.totalPeaces?.piecesCount == item.totalPeaces?.piecesCount
        })
    }
}

extension DataBase {
    struct Tutorial:Codable {
        var needDeleteAiTutorial: Bool = true
        var draggedPuzzle = true
    }
}
