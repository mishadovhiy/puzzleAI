
import Foundation

extension Int {
    func index(_ section:Int, numberOfRows:Int) -> Self {
        (self + 1) + (section * numberOfRows) - 1
    }
}
