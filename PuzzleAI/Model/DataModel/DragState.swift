
import Foundation

enum DragState:Equatable {
    case inactive
    case dragging(translation: CGSize)
}
