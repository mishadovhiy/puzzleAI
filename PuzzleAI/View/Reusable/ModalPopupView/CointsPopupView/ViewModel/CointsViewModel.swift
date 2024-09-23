
import Foundation
import UIKit

extension ModalPopupView.CointsPopupView {
    struct CointsPopupViewModel {
        var type:CointsType
        var selectedItems:[Coint] = [] {
            didSet {
                loadingButtonID = .init()
            }
        }
        /// multiplyes price value of each selected item
        var stopAnimating:Bool = false
     //   var storeKitModel:StoreKitManagerModel?
        var loadingButtonID:UUID = .init()
        var puzzleName:String = ""
        var bonusDayNumber:Int? {
            if type == .dailyRewards {
                return Int(selectedItems.sorted(by: {$0.value >= $1.value}).first?.value ?? 0)
            }
            return nil
        }
        
        mutating func viewDisapeared() {
            if !isLoading {
                selectedItems.removeAll()
            }
            stopAnimating = true
        }
        
        mutating func viewAppeared(){//(_ storeKitModel:StoreKitManagerModel) {
            stopAnimating = true
          //  self.storeKitModel = storeKitModel
            setType()
        }
        
        private mutating func setType() {
            switch type {
            case .buyCoint:
                DB.db.user?.setBalanceFromKeychain()
            case .buyHint(let imageName):
                self.puzzleName = imageName
            case .dailyRewards:
                if let lastLogin = DB.db.lastLogin {
                    let lastValue = lastLogin.numberOfUninterruptedLogins <= RewardType.dailyReward.maxCount ? lastLogin.numberOfUninterruptedLogins : RewardType.dailyReward.maxCount
                    if let selectedItem = cointList.first(where: {$0.price.value == Reward.rewardAmount(lastValue)})?.price {
                        if let _ = DB.db.rewardList.first(where: {$0.period == lastValue})
                        {
                            selectedItems = [selectedItem]
                        }
                    }
                }
            default:break
            }
        }
        
        mutating func cointSelected(_ item:CointListItem, isSelected:Bool) {
            self.stopAnimating = true
            if isSelected {
                selectedItems.removeAll(where: {$0.value == item.price.value})
            } else if type.canSelect {
                if canSelectMulltiple {
                    selectedItems.append(item.price)
                } else {
                    selectedItems = [item.price]
                }
            }
        }
        
        var error:MessageContent? {
//            if let error = storeKitModel?.errorTitle, storeKitModel?.isFailedPurchase == false  {
//                return .init(title: error)
//            }
//            if storeKitModel?.isFailedPurchase == true {
//                return .init(title: "Error purchuasing")
//            }
            return nil
        }
        
        var cointList:[CointListItem] {
            type.cointList ?? []//(storeKitModel?.fetchedProducts ?? [])
        }
        
        var isNoData:Bool {
            type == .buyCoint && error != nil && error?.description != nil
        }
        
        var primaryImage:ImageResource {
            switch type {
            case .buyHint:
                return .buyHintIcon
            default:
                return .cointItems
            }
        }
        
        var selectedItemsTotal:Float {
            if type == .dailyRewards {
                return DB.db.rewardList.filter({!$0.received}).compactMap({Reward.rewardAmount(
                    $0.period
                )}).reduce(0, +)
            } else {
                return selectedItems.compactMap({$0.value}).reduce(0, +)
            }
        }
        
        func requestNotification() {
            let model = NotificationsManager()
            model.requestNotificationAccess(canOpenSettings: false, checkOnly: true) { _ in}
        }
        
        var nextEnabled:Bool {
            if selectedItems.isEmpty {
                return false
            }
            switch type {
            case .dailyRewards:
                return DB.db.rewardList.containsUnreceivedRewards
            case .buyCoint:
                return true
            default:
                if hasEnoughtBalance(amount: selectedItemsTotal) {
                    return true
                } else {
                    return false
                }
            }
        }
        
        var userBalance:Coint? {
            DB.db.user?.getBalance
        }
        
        func hasEnoughtBalance(amount:Float) -> Bool {
            if (userBalance?.value ?? 0) >= amount {
                return true
            } else {
                return false
            }
        }

        var isLoading:Bool {
           // type == .buyCoint ? !(storeKitModel?.productFetchCompleted ?? false) : stopAnimating
            stopAnimating
        }
        
//        func buyProduct() {
//            if let key = selectedItems.first?.id, key != "" {
//                storeKitModel?.buyProduct(key)
//            }
//        }
        
        func updateHintDB() {
            let selectedValuesTotal = Double(selectedValuesTotal)
            for i in 0..<DB.db.puzzleList.count {
                if DB.db.puzzleList[i].imageName == self.puzzleName {
                    DB.db.puzzleList[i].hints += Int(selectedValuesTotal)
                }
            }
        }
        
        func updateCointBalance(completed:@escaping()->()) {
            let isMinus = type != .dailyRewards && type != .buyCoint
            DispatchQueue(label: "db", qos: .userInitiated).async {
                var selected = selectedItemsTotal
                if selected <= 0 && isMinus {
                    
                }
                print(selected, " selectedRefillAmount")
                if DB.db.user?.refillBlance(selected * (isMinus ? -1 : 1), canCheckError: type != .buyCoint) ?? false {
                    switch type {
                    case .buyHint:
                        updateHintDB()
                    case .dailyRewards:
                        var rewards = DB.db.rewardList
                        for i in 0..<rewards.count {
                            rewards[i].received = true
                        }
                        DB.db.rewardList = rewards
                    default:break
                    }
                }
                DispatchQueue.main.async {
                    completed()
                }
            }
        }
        
        /// multiplyes title of each selected item
        var selectedValuesTotal:Float {
            selectedItems.compactMap({
                (($0.value - CointView.priceStartAmount) / Float(CointView.priceMultiplyAmount)) + 1
            }).reduce(0, +)
        }
        
        var isBuyHintType:Bool {
            switch self.type {
            case .buyHint: return true
            default: return false
            }
        }
        
        var canSelectMulltiple:Bool {
            return switch type {
            case .buyCoint, .buyHint:false
            default: true
            }
        }
        
        var nextTitle:String {
            return switch type {
            case .buyCoint:"Pay"
            case .buyHint:"Buy hints"
            case .dailyRewards: nextEnabled ? "Receive" : "Come back tomorrow"
            default: "Receive"
            }
        }

        var descriptionText:String? {
            return switch type {
            case .dailyRewards:"""
Pick up coins for logging into the game daily without skipping. The "Receive" button must be pressed daily, otherwise the day counter will start again.
"""
            case .buyHint:"""
Additional clues for this puzzle can be
purchased here, select the quantity you need
and click the "Buy hints" button
"""
            default: nil
            }
        }
        
        private func isCointSelected(_ item:CointListItem) -> Bool {
            let selectedValue = selectedItems.sorted(by: {$0.value >= $1.value}).first
            return item.price.value > (selectedValue?.value ?? 0)
        }
        
        func isAlpha(isSelected:Bool, _ item:CointListItem) -> Bool {
            if type == .dailyRewards {
                return isCointSelected(item)
            }
            return false
        }
        
        func cointBackgroundColor(isSelected:Bool, item:CointListItem) -> UIColor {
            let color: UIColor = isSelected ? .blueTint : .clear
            if type == .dailyRewards {
                if isAlpha(isSelected: isSelected, item) {
                    return .container
                } else {
                    return isSelected ? (nextEnabled ? .clear : .blueTint) : .blueTint
                }
            } else {
                return color
            }
        }
    }
}


extension ModalPopupView.CointsPopupView.CointsPopupViewModel {
    enum CointsType:Equatable {
        case dailyRewards, buyHint(String), buyAI, unlock(String), buyCoint, cointsPreview
        
        var puzzleName:String? {
            return switch self {
            case .unlock(let str), .buyHint(let str): str
            default: nil
            }
        }
                
        var baseContent:BaseContent {
            return switch self {
            case .buyHint:.init(screenTitle: "Buy hints")
            case .dailyRewards: .init(screenTitle: "Daily Rewards")
            case .buyAI: .init(screenTitle: "Unlock AI puzzle generation")
            case .unlock: .init(screenTitle: "Unlock puzzle")
            case .buyCoint: .init(screenTitle: "Buy Coints")
            case .cointsPreview:.init(screenTitle: "How to get more coints")
            }
        }

        var canSelect:Bool {
            return switch self {
            case .dailyRewards:false
            default: true
            }
        }
        
        var cointList:[CointListItem]? {
            return switch self {
            case .dailyRewards: .cointList(title: "Day")
            case .buyHint: .cointList(title: "Hint", titleFirst: true)
            case .buyCoint:nil
            default: .cointList(title: "coints")
            }
        }
        
        struct BaseContent {
            let screenTitle:String
        }
    }
}
