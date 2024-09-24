//
//  PuzzleListView.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import SwiftUI

struct PuzzleListView: View {
    @State var viewModel:PuzzleListViewModel
    var generateAIPresenting:Binding<Bool>?
    @Binding var startOverPressed:PuzzleItem?
    @Binding var collectPuzzlePresenting:PuzzleItem?
    @Binding var puzzleModalPresenting:PuzzleItem?
    @Binding var showingTutorial:Bool
    
    var body: some View {
        VStack {
            SelectionScrollView(data: viewModel.selectionData, selectedIndex: .init(get: {
                viewModel.getSelectionIndex
            }, set: {
                viewModel.selectionChanged($0)
            }))
            .opacity(viewModel.tutorialDeleteAiPresenting ? 0.1 : 1)
            puzzlesGrid
                .padding(.leading, 16)
                .padding(.trailing, 16)
        }
        .onChange(of: viewModel.tutorialDeleteAiPresenting, perform: { newValue in
            showingTutorial = newValue
        })
        .overlay(content: {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        viewModel.lastScrollID = nil
                        viewModel.scrollToLast()
                    } label: {
                        Image(.scrollTopIndicator)
                            .foregroundColor(.init(uiColor: UIColor(named: "titleColor") ?? .red))
                            .frame(width: 48, height: 48)
                            .background(.blueTint)
                            .cornerRadius(24)
                    }
                    .shadow(color: .init(uiColor: .init(red: 152/255, green: 152/255, blue: 152/255, alpha: 1)).opacity(0.15), radius: 6, y: 2)
                    .shadow(color: .init(uiColor: .init(red: 215/255, green: 215/255, blue: 215/255, alpha: 1)).opacity(0.3), radius: 2, y: 1)

                }
            }
            .opacity(viewModel.needScrollTopButton ? 1 : 0)
            .padding(.trailing, 24)
            .padding(.bottom, 21)
        })
        .background(.generalBackground)
        .onAppear {
            viewModel.tutorialPuzzleNameChanged = {
                self.viewModel.tutorialPuzzleName = $0
            }
            viewModel.dbUpdated = {
                self.viewModel.allList = $0
                self.viewModel.list = $1
                self.viewModel.scrollToLast()
            }
            viewModel.getData()
        }
    }
    
    private var puzzlesGrid:some View {
        GeometryReader { proxy in
            let small = proxy.size.width <= 400
            let extraSmall = proxy.size.width <= 330
            let width = small ? (extraSmall ? 90 : 110) : 140
            let maxCollumns = Int(Int(proxy.size.width) / width)
            if 1 <= maxCollumns {
                let collumns = Array(1..<maxCollumns).compactMap({ _ in
                    GridItem(.flexible(minimum: 50, maximum: 200), spacing: extraSmall ? 8 : 16)
                })
                ScrollViewReader { scrollReader in
                    ScrollView {
                        puzzleGrid(collumns, isSmallScreen: extraSmall, screenSize: proxy.size)
                            .frame(maxWidth:.infinity, maxHeight: .infinity)
                    }
                    .coordinateSpace(name: "scrollView")
                    .frame(alignment: .top)
                    .onPreferenceChange(ContentOffsetKey.self) { value in
                        let percent = value.minY / value.size.height
                        let rowID = CGFloat(viewModel.list.count) * percent
                        if rowID.isFinite && !rowID.isZero {
                            viewModel.lastScrollID = Int(rowID)
                        }
                    }
                    .onChange(of: viewModel.scrollID) { newValue in
                        if let newValue {
                            scrollReader.scrollTo(newValue, anchor: .top)
                        }
                    }
                    .id(viewModel.scrollViewID)
                }
                
            }
        }
    }
    
    func puzzleGrid(_ collumns:[GridItem], isSmallScreen:Bool, screenSize:CGSize) -> some View {
        VStack {
            if viewModel.list.isEmpty && (viewModel.screenType == .library || viewModel.selectedSelectionIndex != 0) {
                NoDataView(imageResurce: .no)
                    .frame(width:screenSize.width, height: screenSize.height * 0.9)
            } else {
                LazyVGrid(columns: collumns, spacing: isSmallScreen ? 8 : 16) {
                    if let _ = generateAIPresenting {
                        PuzzleItemView(image: .constant(.init(imageName: "")), isList: true, presentingPuzzlePopup: .init(get: {
                            generateAIPresenting != nil ? .init(imageName: "") : nil
                        }, set: { newValue in
                            generateAIPresenting?.wrappedValue = newValue != nil ? true : false
                        }))
                    }
                    ForEach(0..<(viewModel.tutorialDeleteAiPresenting ? 1 : viewModel.list.count), id: \.self) { i in
                        if viewModel.list.count - 1 >= i {
                            gridItem(viewModel.list[i], screenSize: screenSize, isFirst: i == 0)
                                .id(i)
                        }
                    }
                }
                .background {
                    GeometryReader { geometry in
                        Color.clear
                            .preference(key: ContentOffsetKey.self, value: geometry.frame(in: .named("scrollView")))
                    }
                }
                Spacer()
            }
        }
    }
    
    func gridItem(_ puzzle:PuzzleItem, screenSize:CGSize, isFirst:Bool) -> some View {
        PuzzleItemView(image: .constant(puzzle), isList: true, presentingPuzzlePopup:$puzzleModalPresenting, reloadUI: {
            viewModel.getData()
        }, isAiViewType:viewModel.screenType == .aiGenerated)
        .disabled(viewModel.tutorialDeleteAiPresenting ? !isFirst : false)
        .overlay {
            if viewModel.canShowTutorialOverley(puzzle.imageName) {
                GeometryReader { geometry in
                    self.tutorialOverleyView(puzzle.imageName, geometry: geometry, screenSize: screenSize)
                }
            }
        }
        .zIndex(isFirst ? 1 : (viewModel.tutorialDeleteAiPresenting ? -1 : 1))

    }
    
    func tutorialOverleyView(_ puzzleName:String, geometry:GeometryProxy, screenSize:CGSize) -> some View {
        TutorialView(title: viewModel.tutorialOverleyText, position: .init(x:screenSize.width - (geometry.size.width / 2), y:5)) {
            viewModel.dismissTutorialPressed()
        }
        .frame(width: screenSize.width, height: 95)
        .position(.init(x: -8, y: geometry.size.height + 50))
    }
}
