
import Foundation
import SwiftUI

extension PuzzleListView {
    struct PuzzleListViewModel {
        var list:[PuzzleItem] = []
        var selectionData:[SelectionScrollView.SelectionData]
        var screenType:ScreenType
        var selectedSelectionIndex:Int = 0
        var allList:[PuzzleItem] = []
        var tutorialPuzzleName:String? = nil
        mutating func scrollToLast() {
            scrollID = lastScrollID ?? 0
            if scrollID ?? 0 == 0 {
                scrollViewID = .init()
            }
        }
        var scrollViewID:UUID = .init()
        var scrollID:Int?
        var needScrollTopButton:Bool = false
        var lastScrollID:Int? {
            get {
                PuzzleListView.PuzzleListViewModel.lastScrollIDHolder[screenType]
            }
            set {
                let new = newValue ?? 0
                PuzzleListView.PuzzleListViewModel.lastScrollIDHolder.updateValue(((new * -1) + (new <= 1 ? 0 : 1)), forKey: screenType)
                needScrollTopButton = (new * -1) >= 3
            }
        }
        static var lastScrollIDHolder:[ScreenType:Int] = [:]
        typealias DBUpdatedCompletion = (_ allData:[PuzzleItem],
                                         _ currentList:[PuzzleItem])->()
        typealias TutorialPuzzleNameChanged = (_ newPuzzleName:String?) -> ()
        var tutorialPuzzleNameChanged: TutorialPuzzleNameChanged?
        var dbUpdated:DBUpdatedCompletion?
        
        init(_ type:ScreenType) {
            self.screenType = type
            self.selectionData = type.filterOptions.compactMap({
                .init(title: $0.rawValue)
            })
            self.allList = []
        }
        
        var selectedSelection: ScreenType.FilterOptions {
            screenType.filterOptions[selectedSelectionIndex]
        }
        
        var tutorialDeleteAiPresenting:Bool {
            (tutorialPuzzleName ?? "") != "" && screenType == .aiGenerated && DB.db.tutorials.needDeleteAiTutorial
        }
        
        var getSelectionIndex:Int {
            selectedSelectionIndex
        }
        
        private mutating func performGetData(completion:@escaping(_ allData:[PuzzleItem])->()) {
            let screnType = screenType
            let tutorialPuzzleName = tutorialPuzzleNameChanged
            DispatchQueue(label: "db", qos: .userInitiated).async {
                let all = DB.db.puzzleList
                if screnType == .aiGenerated {
                    let allAI = all.filter({$0.isCreatedByAI}).sorted(by: {$0.type.hashValue >= $1.type.hashValue})
                    if DB.db.tutorials.needDeleteAiTutorial {
                        tutorialPuzzleName?(allAI.first(where: {$0.aIGenerationType == .byUser})?.imageName)
                    } else {
                        tutorialPuzzleName?(nil)
                    }
                    DispatchQueue.main.async {
                        completion(allAI)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(all)
                    }
                }
            }
        }

        mutating func getData() {
            let completion = dbUpdated
            let scrollSelectionSelected = selectedSelection
            performGetData { allData in
                let list:[PuzzleItem]
                switch scrollSelectionSelected {
                case .inProgress:
                    list = allData.filter({$0.isStarted && !$0.isCompleted})
                case .completed:
                    list = allData.filter({$0.isCompleted})
                case .closed:
                    list = allData.filter({$0.isClosed})
                case .aiGenerated:
                    list = allData.filter({$0.isCreatedByAI})
                case .none:
                    list = allData
                }
                completion?(allData, list)
            }
        }
        
        mutating func selectionChanged(_ newIndex:Int) {
            self.selectedSelectionIndex = newIndex
            self.getData()
        }
        
        mutating func dismissTutorialPressed() {
            withAnimation {
                tutorialPuzzleName = nil
            }
            DispatchQueue(label: "db", qos: .userInitiated).async {
                DB.db.tutorials.needDeleteAiTutorial = false
            }
        }
        
        func gridItemZIndex(_ puzzleName:String) -> Double {
            canShowTutorialOverley(puzzleName) ? 1 : (tutorialDeleteAiPresenting ? -1 : 1)
        }
        
        func canShowTutorialOverley(_ puzzleName:String) -> Bool {
            tutorialDeleteAiPresenting && puzzleName == tutorialPuzzleName
        }
        
        let tutorialOverleyText:String = "To remove a created puzzle using artificial intelligence, long press the card."
    }
}

extension PuzzleListView.PuzzleListViewModel {
    enum ScreenType {
        case library
        case aiGenerated
        
        enum FilterOptions:String, CaseIterable {
            case none = "All puzzles"
            case aiGenerated = "AI Generation"
            case closed = "Closed"
            case inProgress = "In Process"
            case completed = "Completed"
        }
        
        var filterOptions:[FilterOptions] {
            switch self {
            case .aiGenerated:
                let ignored:[FilterOptions] = [.aiGenerated, .closed]
                return FilterOptions.allCases.filter {
                    !ignored.contains($0)
                }
            default: return FilterOptions.allCases
            }
        }
    }
}
