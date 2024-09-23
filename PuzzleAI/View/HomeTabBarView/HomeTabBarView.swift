
import SwiftUI

struct HomeTabBarView: View {
    @Environment(\.scenePhase) var scenePhase

    @ObservedObject var viewModel:HomeViewModel
    @State var collectPuzzlePresenting:PuzzleItem? = nil
    @State var startOverPuzzle:PuzzleItem? = nil
    @State var generateAIPresenting:Bool = false
    @State var puzzleModalPresenting:PuzzleItem? = nil
    @State var tutorialShowing:Bool = false
    
    init() { self.viewModel = .init() }
    
    var body: some View {
        ZStack {
            Color(.generalBackground)
                .frame(maxWidth:.infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all)
            NavigationView {
                ZStack {
                    navigationLinks
                    VStack {
                        if viewModel.viewLoaded {
                            navigationView
                                .opacity(tutorialShowing && viewModel.selectedTab == 1 ? 0.1 : 1)
                                .disabled(tutorialShowing && viewModel.selectedTab == 1)
                            tabBar
                        } else {
                            loaderView
                        }
                    }
                    .onAppear {
                        viewModel.subscribeToDBUpdated()
                        viewModel.configureDB()
                        UITabBar.appearance().isTranslucent = false
                        UITabBar.appearance().backgroundColor = .generalBackground
                        UIApplication.shared.keyWindow?.endEditing(true)
                    }
                    popupsStack
                }.background(.generalBackground)
                    .navigationBarBackButtonHidden(true)
                    .navigationBarHidden(true)
                    .environment(\.colorScheme, .dark)
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .frame(maxHeight: .infinity)
            .background(.generalBackground)
            .padding(.top, 8)
            .onAppear {
                viewModel.subscribeToDBUpdated()
                viewModel.configureDB()
                UITabBar.appearance().isTranslucent = false
                UITabBar.appearance().backgroundColor = .generalBackground
                UIApplication.shared.keyWindow?.endEditing(true)
            }
        }
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .inactive {
                        NotificationsManager().setLocalNotification { _ in}
                    }
                }
    }
    
    private var tabBarContentView:some View {
        HStack {
            switch viewModel.selectedTab {
            case 0:
                PuzzleListView(viewModel: .init(.library), startOverPressed: $startOverPuzzle, collectPuzzlePresenting: $collectPuzzlePresenting, puzzleModalPresenting: $puzzleModalPresenting, showingTutorial: .constant(false))
            case 1:
                UserPuzzlesTabView(generatePuzzlePressenting: $generateAIPresenting, user: $viewModel.userHolder, startOverPuzzle: $startOverPuzzle, collectPuzzlePresenting: $collectPuzzlePresenting, puzzleModalPresenting: $puzzleModalPresenting, showingTutorial: $tutorialShowing)
            case 2:
                SettingsTabView(toHomePressed: .init(get: {
                    false
                }, set: { newValue in
                    if newValue {
                        self.viewModel.firstTabBarAppeared = false
                        self.viewModel.selectedTab = 0
                        self.viewModel.tabBarAppeared()
                    }
                }))
            default:
                NoDataView()
            }
        }
    }
    
    private func tabBarButtonLabel(_ buttonData:HomeViewModel.TabBarData) -> some View {
        VStack {
            Spacer()
            VStack() {
                Image(buttonData.image)
                    .foregroundColor(viewModel.selectedTab == buttonData.index ? .blueTint : .descriptionText)
                Text(buttonData.title)
                    .foregroundColor(viewModel.selectedTab == buttonData.index ? .blueTint : .descriptionText)
                    .setStyle(.descriptionBold)
            }
            Spacer()
        }
    }
    
    private func tabBarButtonsView(_ proxy:GeometryProxy) -> some View {
        let y:CGFloat = proxy.safeAreaInsets.bottom == 0 ? 8 : 3
        return VStack {
            DefaultLine(y:y)
            HStack {
                ForEach(viewModel.tabBarButtonData, id: \.index) { buttonData in
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.14)) {
                            viewModel.selectedTab = buttonData.index
                        }
                    } label: {
                        tabBarButtonLabel(buttonData)
                    }
                    Spacer()
                }
            }
            .padding(.top, proxy.safeAreaInsets.bottom == 0 ? 0.5 : 0)
        }
    }
    
    private var tabBar: some View {
        GeometryReader { geometryProxy in
            VStack {
                tabBarContentView
                    .frame(maxHeight: .infinity)
                    .id(viewModel.reloadID)
                tabBarButtonsView(geometryProxy)
                    .frame(height: 44)
                    .opacity(tutorialShowing && viewModel.selectedTab == 1 ? 0.1 : 1)
                    .disabled(tutorialShowing && viewModel.selectedTab == 1)
            }
            .padding(.bottom, geometryProxy.safeAreaInsets.bottom == 0 ? 10 : 0)
            .tint(.blueTint)
            .onAppear {
                viewModel.tabBarAppeared()
            }
            .animation(.bouncy, value: viewModel.viewLoaded)
            .transition(.move(edge: .bottom))
            .onChange(of: collectPuzzlePresenting) { newValue in
                if newValue != nil {
                    animate {
                        self.puzzleModalPresenting = nil
                    }
                }
            }
        }
    }
    
    private var loaderView:some View {
        HStack {
            Spacer()
            LoadingView()
            Spacer()
        }
        .animation(.bouncy, value: viewModel.viewLoaded)
        .transition(.opacity)
    }
    
    // MARK: Popuver View
    private var popupsStack:some View {
        ZStack {
            collectPuzzlePopup
            cointsPopup
            rewardsPopup
        }
    }
    
    private var collectPuzzlePopup: some View {
        ModalPopupView(popupData:.constant(.init(puzzle: puzzleModalPresenting)), isPresenting: isPuzzleModalPresenting, isCollectPuzzlePresenting: $collectPuzzlePresenting)
    }
    
    private var cointsPopup:some View {
        ModalPopupView.configureCoint(.buyCoint, isPresenting: addCointsPresenting)
    }
    
    private var rewardsPopup:some View {
        ModalPopupView.configureCoint(.dailyRewards, isPresenting: dailyRewardPresenting)
            .onChange(of: dailyRewardPresenting.wrappedValue) { newValue in
                if !newValue {
                    NotificationsManager().requestNotificationAccess(canOpenSettings: false, checkOnly: false) { _ in }
                    DispatchQueue(label: "db", qos: .userInitiated).async {
                        if !DB.db.rewardList.containsUnreceivedRewards {
                            if (DB.db.lastLogin?.numberOfUninterruptedLogins ?? 0) >= 7 {
                                print("removedrewards")
                                DB.db.lastLogin = nil
                                DB.db.rewardList.removeAll(where: {$0.type == .dailyReward})
                            }
                        }
                    }
                }
            }
    }
    
    // MARK: Component view
    private var navigationView: some View {
        VStack(spacing:12) {
            HStack(spacing:1) {
                Text(viewModel.viewTitle)
                    .setStyle(.navigationTitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.2)
                Spacer()
                
                Button {
                    animate {
                        viewModel.coordinator.update(.init(isGotDailyRewardPresenting:true))
                    }
                } label: { giftNavigationButton }
                
                Spacer().frame(width: 12)
                Button {
                    viewModel.coordinator.update(.init(isAddCointsPresenting: true))
                } label: {
                    CointView(coint:.constant(viewModel.userHolder?.getBalance ?? .init(value: 0)), isNavigationController: true, needOutline: true, isValueCutted: true)
                }

            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .frame(height: 44)
            .animation(.bouncy, value: viewModel.viewLoaded)
            .transition(.move(edge: .top))
            DefaultLine()
        }
    }
    
    private var navigationLinks:some View {
        VStack {
            NavigationLink("Generate puzzle", isActive: $generateAIPresenting) {
                GeneratePuzzleView()
            }
            .hidden()
            NavigationLink("Collect puzzle", isActive:isCollectPuzzlePresenting) {
                if let collectPuzzlePresenting {
                    CollectPuzzleView(puzzle: collectPuzzlePresenting) { newPuzzle in
                        self.startOverPuzzle = newPuzzle
                    }
                } else {
                    NoDataView()
                }
            }
            .hidden()
        }
    }
    
    var giftNavigationButton:some View {
        ZStack {
            VStack {
                Image(.present)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.blueTint)
            }.padding(8)
            
            RoundedRectangle(cornerRadius: 50)
                .stroke(.descriptionText, style: .init(lineWidth: 0.5))
        }.frame(width: 44, height: 44)
    }
    
    // MARK: Coordinator
    private var dailyRewardPresenting:Binding<Bool> {
        .init {
            viewModel.coordinator.dailyRewardPresenting
        } set: { isPresenting in
            animate {
                viewModel.coordinator.update(.init(isGotDailyRewardPresenting: isPresenting))
            }
        }
    }
    
    private var addCointsPresenting:Binding<Bool> {
        .init(get: {
            viewModel.coordinator.addCointsPresenting
        }, set: { isPresenting in
            animate {
                viewModel.coordinator.update(.init(isAddCointsPresenting: isPresenting))
            }
        })
    }
    
    private var isPuzzleModalPresenting:Binding<Bool> {
        .init(get: {
            puzzleModalPresenting != nil
        }, set: {
            if !$0 {
                withAnimation {
                    puzzleModalPresenting = nil
                }
            }
        })
    }
    
    private var isCollectPuzzlePresenting:Binding<Bool> {
        .init(get: {
            collectPuzzlePresenting != nil
        }, set: {
            if !$0 {
                collectPuzzlePresenting = nil
            }
        })
    }
}

