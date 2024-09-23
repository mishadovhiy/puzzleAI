
import Foundation

struct LastLoginRowData:Codable {
    var lastLoginDate:Date?
    var numberOfUninterruptedLogins:Int = 0
}

struct LastLoginManager {
    struct ApplicationLaunchedCompletion {
        var isRewardsGranded:Bool = false
    }
    
    func applicationDidLoad(testValue:Int? = nil, completion:@escaping(ApplicationLaunchedCompletion)->()) {
        startCheckingRewards(testValue: testValue, completion: completion)
    }
    
    private func startCheckingRewards(testValue:Int? = nil, completion:@escaping(ApplicationLaunchedCompletion)->()) {
        let completionNil = {
            DispatchQueue.main.async {
                completion(.init())
            }
        }
        DispatchQueue.init(label: "appLaunch", qos: .userInitiated).async {
            let last = DB.db.lastLogin ?? .init()
            let fromDate:Date?
            if let _ = testValue {
                fromDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
            } else {
                fromDate = last.lastLoginDate
            }
            let daysBetweenNow = fromDate?.dateDifference()
#if DEBUG
            print("startCheckingRewards: days between now and last login: ", daysBetweenNow ?? .init())
#endif
            if daysBetweenNow?.day ?? 0 == 1 || last.lastLoginDate == nil {
                let rewardGranded = saveDate(with: testValue ?? (last.numberOfUninterruptedLogins + 1))
                DispatchQueue.main.async {
                    completion(.init(isRewardsGranded: rewardGranded))
                }
            } else if daysBetweenNow?.day ?? 0 > 1 {
                setTodayLogin()
                completionNil()
            } else {
                completionNil()
            }
        }
    }
    
    private func saveDate(with dayNumber:Int) -> Bool {
        let new = LastLoginRowData(lastLoginDate: Date(), numberOfUninterruptedLogins: dayNumber)
        DB.db.lastLogin = new
        return checkRewards(uniterruptedLogin: new)
    }
    
    /// sets login number to zero, will grand unreceived coins as .numberOfUninterruptedLogins will change, starting from the last received .numberOfUninterruptedLogins before login number setted to zero
    /// - Example: before called setTodayLogin(), numberOfUninterruptedLogins was 3, user should login 4 times in a row (after setTodayLogin called), to receive coins for 4th day, and all granded coins not gonna grand for the second time
    private func setTodayLogin() {
        let _ = saveDate(with: 0)
        var new = DB.db
        new.lastLogin = nil
        new.rewardList.removeAll()
        DB.db = new
    }
    
    /// - Returns: reward granded
    private func checkRewards(uniterruptedLogin:LastLoginRowData) -> Bool {
        let rewards = Array(DB.db.rewardList)
        if rewards.canGrand(numberOfLogins: uniterruptedLogin.numberOfUninterruptedLogins, type: .dailyReward) {
#if DEBUG
            print("grandingRewardsFor: ", uniterruptedLogin)
#endif
            DB.db.rewardList.removeAll(where: {$0.period == uniterruptedLogin.numberOfUninterruptedLogins})
            DB.db.rewardList.append(.init(type: .dailyReward, period: uniterruptedLogin.numberOfUninterruptedLogins))
            return true
        } else {
            return false
        }
    }
}
