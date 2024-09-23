
import SwiftUI

struct ModalPopupViewModel {
    var popupDataUpdateble:ModalPopupViewModel.ModalPopupData = .init()
    let paddings:CGFloat = 16
    var cointsType:ModalPopupView.CointsPopupView.CointsPopupViewModel.CointsType? = nil

    func isSmallDevice(_ geometrySize:CGSize) -> Bool {
        var minSize:CGSize = .init(width: 480, height: 400)
        if cointsType != nil || popupDataUpdateble.difficulty != nil {
            minSize.width = 380
            minSize.height = 680
        }
        return geometrySize.height <= minSize.height && geometrySize.width <= minSize.width
    }
    
    var screenTitle:String {
        return popupDataUpdateble.screenTitle ?? (cointsType?.baseContent.screenTitle ?? "Unknown")
    }
    
    struct ModalPopupData:Equatable {
        var id:UUID = .init()
        static func == (lhs: ModalPopupData, rhs: ModalPopupData) -> Bool {
            if lhs.id != rhs.id {
                if lhs.difficulty == nil && rhs.difficulty == nil && lhs.puzzle != rhs.puzzle {
                    return false
                }
            }
            let imageL = lhs.difficulty?.imageName ?? lhs.puzzle?.imageName
            let imageR = rhs.difficulty?.imageName ?? rhs.puzzle?.imageName

            if imageL == imageR {
                if lhs.difficulty == rhs.difficulty {
                    return true
                } else if lhs.puzzle == rhs.puzzle {
                    if lhs.puzzle != rhs.puzzle {
                        return false
                    }
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        }
        var puzzle:PuzzleItem? = nil
        var difficulty:PuzzleItem? = nil
        
        fileprivate var screenTitle:String? {
            if let _ = difficulty {
                return "Choose a difficulty"
            }
            if let puzzle {
                return !puzzle.isStarted ? "Get This Puzzle" : "Continue or restart puzzle"
            } else {
                return nil
            }
        }
    }
}
