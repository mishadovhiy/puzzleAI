
import Foundation
import UIKit

extension HomeTabBarView {
    final class HomeViewModel:ObservableObject {
        @Published var coordinator:HomeCoordinator = .init()
        @Published var viewLoaded = false
        @Published var selectedTab:Int = 0
        @Published var reloadID = UUID()
        @Published var userHolder:User?
        let tabBarButtonData:[TabBarData] = [
            .init(index: 0, title: "Library", image: .libraryTab),
            .init(index: 1, title: "My puzzles", image: .myPuzzlesTab),
            .init(index: 2, title: "Settings", image: .settingsTab)
        ]
        
        init(viewLoaded: Bool = false) {
            self.coordinator = .init()
            self.viewLoaded = viewLoaded
            if let _ = DB.dbHolder, let db = DB.db.user {
                self.userHolder = db
            } else {
                DispatchQueue.init(label: "db", qos: .userInitiated).async {
                    let user = DB.db.user
                    DispatchQueue.main.async {
                        self.userHolder = user
                    }
                }
            }
        }
        var tabBarCanAppear:Bool = false
        var firstTabBarAppeared:Bool = false
        
        var viewTitle:String {
            if selectedTab <= tabBarButtonData.count - 1 {
                return             tabBarButtonData[selectedTab].title
            } else {
                return "Unrecognized selection"
            }
        }
        
        func tabBarAppeared() {
            if !tabBarCanAppear {
                return
            }
            if firstTabBarAppeared {
                return
            }
            firstTabBarAppeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                Task(priority: .utility) {
                    DB.db.user?.setBalanceFromKeychain()
                    self.checkLastLogin()
                }
            })
        }
        
        func subscribeToDBUpdated() {
            DB.userPublisher.cancellable = DB.userPublisher.publisher
                .sink(receiveCompletion: {_ in}, receiveValue: {
                    let ignoreReload = self.userHolder == nil
                    self.userHolder = $0 ?? .init()
                    if !ignoreReload {
                        self.reloadID = UUID()
                    }
#if DEBUG
                    print("user database updated at: \(Date()) ", #file, #line)
#endif
                })
        }
        var viewLoadCalled = false
        func configureDB() {
            if !viewLoaded && !viewLoadCalled {
                viewLoadCalled = true
                var needAppearCall = false
                if DB.db.puzzleList.isEmpty {
                    self.tabBarCanAppear = false
                    needAppearCall = true
                }
                DB.configure {
                    DispatchQueue.main
                        .asyncAfter(deadline: .now() + .seconds(2), execute: {
                            animate {
                                self.tabBarCanAppear = true
                                self.viewLoaded = true
                                if needAppearCall {
                                    self.tabBarAppeared()
                                }
                            }
                        })
                }
            }
        }
                
        private func checkLastLogin() {
            let lastLogin = LastLoginManager()
            lastLogin
                .applicationDidLoad(completion: {
                    launchCompletion in
                    if launchCompletion.isRewardsGranded {
                        animate {
                            self.coordinator
                                .update(.init(isGotDailyRewardPresenting: true))
                        }
                    }
                })
        }

    }
}

extension HomeTabBarView.HomeViewModel {
    struct TabBarData {
        let index:Int
        let title:String
        let image:ImageResource
    }
    
    struct HomeCoordinator {
        private var isGotDailyRewardPresenting:Bool = false
        var dailyRewardPresenting:Bool {
            isGotDailyRewardPresenting
        }
        private var isAddCointsPresenting:Bool = false
        var addCointsPresenting:Bool {
            isAddCointsPresenting
        }
        mutating func update(_ new:Self) {
            self = new
        }
        
        init(isAddCointsPresenting: Bool = false, isGotDailyRewardPresenting:Bool = false
        ) {
            self.isAddCointsPresenting = isAddCointsPresenting
            self.isGotDailyRewardPresenting = isGotDailyRewardPresenting
        }
    }
}
