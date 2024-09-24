//
//  DifficultyPuzzleView.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import SwiftUI

struct DifficultyPuzzleView: View {
    @State var puzzle:PuzzleItem
    @Binding var isPresenting:Bool
    @Binding var isCollectPuzzlePresenting:PuzzleItem?
    @State var viewModel:DifficultyPuzzleViewModel = .init()
    
    var body: some View {
        VStack {
            PuzzleItemView(image: .constant(puzzle), presentingPuzzlePopup: .constant(nil))
                .frame(width:220, height: 220)
            Spacer()
                .frame(height: 15)
            CointView(coint: .constant(viewModel.puzzle.reward), labelText: "Reward:")
            Spacer()
                .frame(height: 10)
            ScrollViewReader(content: { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    difficultyScrollView(needSpaces: true)
                }
                .frame(height: viewModel.difficultyCellSize(itemID: viewModel.selectedDifficulty.rawValue).height)
                .coordinateSpace(name: "scrollView")
                .onPreferenceChange(ContentOffsetKey.self) { value in
                    self.viewModel.scrollOffsetChanged(value.minX)
                }
                .onChange(of: viewModel.targetIndex) { index in
                    if let index = index {
                        withAnimation {
                            proxy.scrollTo(index, anchor: .top)
                        }
                    }
                }
            })
            Text("Number of parts")
                .setStyle()
            Spacer()
                .frame(height: 18)
            HStack(spacing:12) {
                puzzleTypeView()
                puzzleTypeView(true)
            }
            Spacer()
                .frame(height: 32)
            LoadingButton(data: .init(title: "Start Playing", pressed: {
                self.viewModel.startOverPressed()
            }), nextEnabled: viewModel.nextEnabled, stopAnimation: $viewModel.stopButtonAnimations)
        }
        .onChange(of: puzzle) { newValue in
            viewModel.puzzle = newValue
        }
        .onChange(of: viewModel.selectedDifficulty, perform: { newValue in
            self.puzzle.totalPeaces = newValue
        })
        .onChange(of: viewModel.selectedPuzzleType) { newValue in
            self.puzzle.type = newValue
        }
        .onAppear {
            viewModel.puzzle = self.puzzle
            viewModel.toStartOverPressed = {
                isCollectPuzzlePresenting = $0
            }
        }
    }
    
    func difficultyScrollView(needSpaces:Bool) -> some View {
        let spaceWidth = viewModel.viewTotalWidth / (viewModel.selectedPuzzleType == .puzzle ? 5 : 3)
        return LazyHGrid(rows: [
            GridItem(.flexible(minimum: 50, maximum: 200), spacing: 12)
        ], spacing: 12, content: {
            Spacer().frame(width: spaceWidth)
            ForEach(0..<viewModel.peacesCount.count, id: \.self) { i in
                puzzleCountView(viewModel.peacesCount[i], itemID: i)
            }
            Spacer().frame(width: spaceWidth)
        })
        .background {
            GeometryReader { geometry in
                Color.clear
                    .preference(key: ContentOffsetKey.self, value: geometry.frame(in: .named("scrollView")))
            }
        }
    }
    
    func puzzleCountView(_ item:Int, itemID:Int) -> some View {
        let cellSize = viewModel.difficultyCellSize(itemID: itemID)
        return Button(action: {
            self.viewModel.targetIndex = itemID
        }, label: {
            ZStack {
                Image(viewModel.selectedPuzzleType == .puzzle ? .puzzle : .rectangleType)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(viewModel.countImageColor(itemID))
                VStack {
                    Text("\(item)")
                        .foregroundColor(viewModel.countTextColor(itemID))
                        .setStyle(.defaultBold)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(width:cellSize.width, height:cellSize.height)
            .animation(.interpolatingSpring(duration: 0.15), value: cellSize)
            .transition(.identity)
        })
    }
    
    func puzzleTypeView(_ isSquare:Bool = false) -> some View {
        let isViewSquerSelected = viewModel.selectedPuzzleType == .square
        return Button {
            withAnimation(.bouncy) {
                viewModel.selectedPuzzleType = isSquare ? .square : .puzzle
            }
        } label: {
            ZStack {
                Circle()
                    .stroke((isViewSquerSelected && isSquare) || (!isViewSquerSelected && !isSquare) ? .blueTint : .descriptionText, lineWidth: 0.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Image(isSquare ? .rectangleType : .smallPuzzle)
                    .foregroundColor(viewModel.typeTextColor(isSquare))
            }
            .frame(width:44, height: 44)
        }
    }
}

