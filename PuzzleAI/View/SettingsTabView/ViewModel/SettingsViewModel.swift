
import Foundation
import UserNotifications
import UIKit

extension SettingsTabView {
    struct SettingsViewModel {
        var shareItem:Any? = nil
        private var fileManager:FileManagerModel = .init()
        var isLoading:Bool = false
        var alertDeletePresenting:Bool = false
        let confirmDeleteDataText:String = """
Are you sure you want to clear the data? All progress will be lost and so will the created puzzles using AI.
"""
        var bundleVersion:String {
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "[unknown]"
        }
        
        mutating func deleteDataPressed(completion:@escaping()->()) {
            self.isLoading = true
            let selfHolder = self
            DispatchQueue(label: "db", qos: .userInitiated).async {
                selfHolder.fileManager.deleteDBAllImages(completion:{
                    completion()
                })
            }
        }
        
        func rateAppPressed() {
            let storekit = StoreKitManager()
            storekit.toAppReview()
        }
        
        mutating func shareAppPressed() {
            if let url: URL = URL(string: "https://apps.apple.com/app/id\(Keys.appID)")
            {
                self.shareItem = url
            }
        }
        
        func termsOfUsePressed() {
            UIApplication.shared.open(.init(string: "https://google.com")!)
        }
        
        func privacyPolicyPressed() {
            UIApplication.shared.open(.init(string: "https://google.com")!)
        }
        
        func requestNotificationAccess(canOpenSettings:Bool = false, checkOnly:Bool = false, completion:@escaping(_ granded:Bool)->()) {
            NotificationsManager().requestNotificationAccess(canOpenSettings: canOpenSettings, checkOnly: checkOnly, completion: completion)
        }
    }
}
