
import SwiftUI

struct NotificationsManager {
    private func open(url:String) {
        if let url: URL = URL(string: url),
           UIApplication.shared.canOpenURL(url)
        {
            UIApplication.shared.open(url)
        }
    }
    
    private func toAppSettings() {
        self.open(url: UIApplication.openSettingsURLString)
    }
    
    func requestNotificationAccess(canOpenSettings:Bool = false, checkOnly:Bool = false, completion:@escaping(_ granded:Bool)->()) {
        if checkOnly {
            UNUserNotificationCenter.current().getNotificationSettings { result in
                DispatchQueue.main.async {
                    if canOpenSettings && result.authorizationStatus != .authorized {
                        toAppSettings()
                    }
                    completion(result.authorizationStatus == .authorized)
                }
            }
        } else {
            UNUserNotificationCenter.current().getNotificationSettings {
                if $0.authorizationStatus == .denied && canOpenSettings {
                    DispatchQueue.main.async {
                        completion(false)
                        self.toAppSettings()
                    }
                } else if $0.authorizationStatus == .authorized && canOpenSettings {
                    DispatchQueue.main.async {
                        completion(true)
                        self.toAppSettings()
                    }
                } else {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                        DispatchQueue.main.async {
                            completion(granted)
                        }
                    }
                }
            }
        }
    }

}


extension NotificationsManager {
    func setLocalNotification(completion:@escaping(_ error:Bool)->()) {
        
        let center = UNUserNotificationCenter.current()
        let threadID = "DailyRewardsReminder"
        center.removePendingNotificationRequests(withIdentifiers: [threadID])
        center.getNotificationSettings { (settings) in
            if settings.authorizationStatus != .authorized {
                completion(false)
                return
            }
        }
        let content = UNMutableNotificationContent()
        content.title =  (Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? (Bundle.main.infoDictionary?["CFBundleName"] as? String)) ?? "Puzzle Game"
        content.body = """
Hey new puzzles are waiting for you, don't forget we have daily login bonuses.
"""
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "3DaysReminder"
        content.threadIdentifier = threadID
        let dateComponents = Calendar.current.date(byAdding: .day, value: 3, to: Date())?.dateComponents
        guard let dateComponents else {
            fatalError()
        }
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: content.threadIdentifier,
                                            content: content, trigger: trigger)
        center.add(request) { (error) in
            if error != nil {
                completion(false)
            } else {
                completion(true)
            }
        }
    }
}
