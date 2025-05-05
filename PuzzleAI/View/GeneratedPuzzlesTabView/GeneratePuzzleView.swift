//
//  GeneratePuzzleView.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import SwiftUI

struct GeneratePuzzleView: View {
    @State var viewModel:GeneratePuzzleViewModel = .init()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometryProxy in
            VStack() {
                SuperNavigationView(title: viewModel.title(.navigationTitle), rightButtons: {})
                contentView
                    .frame(height: viewModel.isLoading ? .zero : .none)
                    .animation(.bouncy, value: viewModel.isLoading)
                    .transition(.move(edge: .bottom))
                    .clipped()
                
                primaryButton
                Spacer()
                    .frame(height: 16)
            }
            .padding(.top, geometryProxy.safeAreaInsets.top)
            .background(.generalBackground)
            .navigationBarBackButtonHidden(true)
            .fullScreenCover(isPresented: isResultPresenting, content: {
                ResultGeneratePuzzle(editorText: viewModel.prompt, newImage: viewModel.puzzleResponse?.resultImage, imageSaved: imageSavePressed) {
                    withAnimation {
                        generatePressed()
                    }
                }
            })
            .popover(isPresented: .constant(viewModel.error != nil)) {
                NoDataView(text: viewModel.error?.title)
                    .onDisappear {
                        viewModel.error = nil
                    }
            }
            .onTapGesture {
                viewModel.dismissKeyboard()
            }
            .gesture(
                DragGesture()
                    .onChanged({ value in
                        viewModel.dismissKeyboard()
                    })
            )
        }
    }
    
    var primaryButton:some View {
        HStack {
            if viewModel.isLoading {
                LoadingView(isLotille: .aiGeneration, size: 150, forceHideImage: true)
                    .scaleEffect(0.3)
            } else {
                Button {
                    PuzzleAIApp.bannerCompletedPresenting = {
                        withAnimation {
                            generatePressed()
                        }
                    }
                    PuzzleAIApp.adPresenting.send(true)
                } label: {
                    HStack(alignment:.center) {
                        Spacer()
                        HStack(spacing:8) {
                            Image(.aiStick)
                                .foregroundColor(.init(uiColor: viewModel.nextImageTintColor))
                                .frame(width: 24)
                                Text(viewModel.title(.nextTitle))
                                .setStyle(.defaultBold)
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
                .setStyle(viewModel.isNextEnabled)
                .frame(maxWidth: .infinity)
                
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 16)
    }
        
    var photoStyleGrid:some View {
        VStack {
            if #available(iOS 17.0, *) {
                ScrollView(.horizontal, showsIndicators: false) {
                    photoGridScrollContent
                }
                .scrollTargetBehavior(.viewAligned)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    photoGridScrollContent
                }
            }
        }
    }
    
    func gridItem(_ item: GeneratePuzzleView.GeneratePuzzleViewModel.PhotoStyle) -> some View {
        VStack(alignment:.leading, spacing:12, content: {
            ZStack(content: {
                if viewModel.selectedItem == item {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.title, lineWidth: 1)
                }
                Image(uiImage: .init(name: item.content.imageName!)!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width:140, height: 140)
                    .scaledToFit()
                    .cornerRadius(8)
            })
            HStack {
                VStack(alignment:.leading, spacing:8) {
                    Text(item.content.title)
                        .setStyle(.defaultArticleBold)
                    Text(item.content.description ?? "")
                        .setStyle(.small)
                }
                Spacer()
            }
            
        })
    }
    
    var photoGridScrollContent:some View {
        HStack(alignment:.top) {
            Spacer().frame(width: 16)
            ForEach(GeneratePuzzleViewModel.PhotoStyle.allCases, id: \.rawValue) { item in
                Button {
                    withAnimation(.bouncy) {
                        self.viewModel.selectedItem = item
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.descriptionText, lineWidth: 0.5)
                            .padding(-16)
                        gridItem(item)
                    }
                    .frame(maxWidth:140, minHeight: 220)
                    .padding(16)
                    .background(viewModel.selectedItem == item ? .blueTint : .clear)
                    .cornerRadius(16)
                }
            }
            Spacer().frame(width: 16)
        }

    }
    
    var contentView:some View {
        VStack {
            if #available(iOS 16.0, *) {
                ScrollView {
                    VStack {
                        scrollContent
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            } else {
                ScrollView {
                    scrollContent
                }
            }
        }
    }
    
    var scrollContent:some View {
        VStack(alignment:.leading) {
            Spacer()
                .frame(height: 10)
            VStack {
                TextEditorView(text: $viewModel.prompt, title: viewModel.title(.textEditorTitle), placeholder: viewModel.title( .placeholder))
                    .frame(height: 170)
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            Spacer()
                .frame(height: 16)
            VStack(alignment:.leading, spacing:8) {
                Text(viewModel.title(.photoStyle))
                    .setStyle(.middle)
                    .padding(.leading, 16)
                    .padding(.trailing, 16)
                photoStyleGrid
            }
            Spacer()
                .frame(height: 8)
            VStack(alignment:.leading, spacing: 2) {
                Text(viewModel.title(.promtExample))
                    .setStyle(.small)
                Text(viewModel.title(.promtExampleText))
                    .setStyle(.descriptionSmall)
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            Spacer()
                .frame(height: 16)
        }

    }
    
    func generatePressed() {
        viewModel.generateRequestPressed(completion: { image, error in
            animate(.linear(duration: 0.2)) {
                self.viewModel.isLoading = false
            } completion: {
                if let image {
                    self.viewModel.puzzleResponse = .init(resultImage: image)
                } else {
                    self.viewModel.error = error ?? .init(title: "Error loading generated image")
                }
            }
        })
    }
    
    var isResultPresenting:Binding<Bool> {
        .init(get: {
            viewModel.puzzleResponse != nil
        }, set: {
            if !$0 {
                viewModel.puzzleResponse = nil
            }
        })
    }
    
    var imageSavePressed:Binding<Bool> {
        .init(get: {
            false
        }, set: {
            if $0 {
                dismiss()
            }
        })
    }
}

