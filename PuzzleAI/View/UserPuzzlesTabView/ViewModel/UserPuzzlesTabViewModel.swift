
import Foundation

struct UserPuzzlesTabViewModel {
    var isPaidAI: Bool {
        DB.db.user?.aiPaid ?? false
    }
}
