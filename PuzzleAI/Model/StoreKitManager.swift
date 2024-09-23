
import Foundation
import StoreKit

final class StoreKitManager {
    
    func toAppReview() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
    
}
