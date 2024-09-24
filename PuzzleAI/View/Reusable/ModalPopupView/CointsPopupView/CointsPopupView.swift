//
//  CointsPopupView.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import SwiftUI

extension ModalPopupView {
    struct CointsPopupView: View {
        @State var viewModel:CointsPopupViewModel
        @Binding var isPresenting:Bool
        var nextPressed:Binding<Bool>?
        var geometrySize: CGSize
        
        var body: some View {
            VStack(alignment:.center) {
                if viewModel.type == .cointsPreview {
                    Spacer()
                }
                if viewModel.isBuyHintType {
                    HStack {
                        Spacer()
                        coinView
                        Spacer()
                    }
                }
                Image(viewModel.primaryImage)
                    .frame(height: 90)
                if let descriptionText = viewModel.descriptionText {
                    Text(descriptionText)
                        .setStyle(.descriptionBold)
                        .frame(minHeight: 75)
                        .multilineTextAlignment(.center)
                }
                Spacer()
                    .frame(height: 16)
                if viewModel.type != .cointsPreview {
                    gridView
                }
                if viewModel.isNoData {
                    NoDataView(text: viewModel.error?.description, needImage: false)
                }
                Spacer()
                    .frame(height: 32)
                if viewModel.type == .cointsPreview {
                    VStack(alignment:.leading) {
                        Text("To get more coins, you can:")
                            .setStyle()
                        Text("- Log in everyday and receive Daily rewars")
                            .setStyle()
                        Text("- Collect puzzles to get more rewards")
                            .setStyle()
                    }
                } else {
                    VStack {
                        if viewModel.type == .buyCoint {
                            LoadingView(isLotille: nil)
                                .scaledToFit()
                                .clipped()
                                .opacity(viewModel.isLoading ? 1 : 0)
                                .animation(.bouncy, value: viewModel.isLoading)
                                .transition(.move(edge: viewModel.isLoading ? .bottom : .top))
                                .frame(height: viewModel.isLoading ? 50 : 0)
                        }
                        LoadingButton(data:.init(title: viewModel.nextTitle, pressed: nextButtonPressed), nextEnabled: viewModel.nextEnabled, canAnimate: true, stopAnimation: .constant(viewModel.isLoading))
                            .id(viewModel.loadingButtonID)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .onChange(of: isPresenting, perform: { newValue in
                if !newValue {
                    viewModel.viewDisapeared()
                } else {
                    viewModel.stopAnimating = true
                    viewModel.loadingButtonID = .init()
                }
            })
            .onAppear {
                viewModel.viewAppeared(.init(fetchedProducts: {
                    self.viewModel.storeKitModel?.fetchedProducts = $0
                }, statePurchuaseSuccess: {
                    self.isPresenting = $0
                }, error: {
                    self.viewModel.storeKitModel?.storeKitError = $0
                }, loading: {
                    self.viewModel.storeKitModel?.storeKitLoading = $0
                }, viewModelGet: {
                    self.viewModel
                }))
            }
        }
        
        private var gridView:some View {
            let isSmall = geometrySize.width <= (4 * 100)
            let collumns = Array(0..<(isSmall ? 3 : 4)).compactMap { _ in
                GridItem(.flexible(minimum: 80, maximum: 90), spacing: 12, alignment: .center)
            }
            return LazyVGrid(columns: collumns, alignment: .center) {
                ForEach(viewModel.cointList, id: \.price.value) {
                    cointsGridItem($0)
                }
            }
            .frame(alignment: .center)
        }
        
        private func cointsGridItem(_ item:CointListItem) -> some View {
            let isSelected = viewModel.selectedItems.contains(where: {$0.value == item.price.value})
            return Button(action: {
                viewModel.cointSelected(item, isSelected: isSelected)
            }, label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.blueTint, lineWidth: viewModel.isAlpha(isSelected: isSelected, item) ? 0 : 1)
                    VStack(spacing:4) {
                        Text(item.title)
                            .setStyle(.small)
                        Image(.coint)
                        Text(item.price.stringValue)
                            .setStyle(.defaultArticleBold)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                }
                .frame(width: 81)
                .background(Color(uiColor: viewModel.cointBackgroundColor(isSelected: isSelected, item: item)))
                .opacity(viewModel.isAlpha(isSelected: isSelected, item) ? 0.5 : 1)
                .cornerRadius(16)
            })
            .disabled(!viewModel.type.canSelect)
        }
        
        var coinView: some View {
            HStack {
                Text("Balance")
                    .setStyle(.middle)
                CointView(coint: .constant(viewModel.userBalance ?? .init(value: 0)))
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .padding(.trailing, 6)
                    .overlay {
                        RoundedRectangle(cornerRadius: 50)
                            .stroke(.descriptionText, style: .init(lineWidth: 0.5))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
            }
        }
        
        
        // MARK: - IBAction
        private func nextButtonPressed() {
            if let _ = nextPressed {
                nextPressed?.wrappedValue = true
                isPresenting = false
            } else {
                switch viewModel.type {
                case .buyCoint:
                    viewModel.buyProduct()
                default:
                    viewModel.updateCointBalance(completed: {
                        isPresenting = false
                        viewModel.requestNotification()
                    })
                }
            }
        }
    }
}
