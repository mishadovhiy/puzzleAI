
import Foundation

struct ButtonData {
    var title:String
    var type:Style = .primary
    var pressed:(()->())?
    
    enum Style {
        case primary
        case secondary
    }
}
