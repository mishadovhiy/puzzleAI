//
//  PuzzleCompletionView.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import SwiftUI

struct PuzzleCompletionView: View {
    
    @Binding var puzzle:PuzzleItem
    @Environment(\.dismiss) private var dismiss
    @State var viewModel:PuzzleCompletionViewModel = .init()
    var originalImage:UIImage
    
    var body: some View {
        ZStack {
            Color.generalBackground
                .ignoresSafeArea(.all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack {
                SuperNavigationView(title: "", needBackButton: .closeIcon) {
                    CointView(coint: .constant(viewModel.userBalance), isNavigationController: true, needOutline: true)
                }
                GeometryReader(content: { GeometryProxy in
                    ScrollView(showsIndicators:false) {
                        VStack {
                            Spacer()
                            VStack(spacing:6){
                                Text("Puzzle complete!")
                                    .setStyle(.bellowBigBlue)
                                CointView(coint:.constant(puzzle.reward), labelText: "You earned:")
                            }
                            Spacer()
                                .frame(height: 18)
                            if let image = image {
                                HStack {
                                    Image(uiImage: image)
                                        .resizable()
                                        .clipped()
                                        .cornerRadius(18)
                                        .aspectRatio(contentMode: .fit)
                                }
                                .padding(.leading, 16)
                                .padding(.trailing, 16)
                            }
                            Spacer()
                                .frame(height: 18)
                            Text("Pieces")
                                .setStyle(.descriptionSmall)
                            HStack {
                                Text("X")
                                    .setStyle(.descriptionSmall)
                                Text(puzzle.price.stringValue)
                                    .setStyle(.bigDescription)
                            }
                            Spacer()
                            
                        }
                        .frame(minHeight: GeometryProxy.size.height)
                    }
                })
                .padding(.leading, 16)
                .padding(.trailing, 16)
                VStack {
                    Button {
                        viewModel.sharePressed()
                    } label: {
                        HStack(alignment:.center, content: {
                            Spacer()
                            HStack(spacing:6) {
                                Image(.share)
                                    .foregroundColor(.init(uiColor: .init(named: "titleColor") ?? .red))
                                Text("Share result")
                                    .setStyle(.defaultBold)
                            }
                            Spacer()
                        })
                        .frame(maxWidth: .infinity)
                    }
                    .primaryStyle
                    
                    LoadingButton.configure(data: .init(title: "Start over", type: .secondary, pressed: {
                        self.viewModel.startOverPressed {
                            self.puzzle = $0
                            self.dismiss()
                        }
                    }), canAnimate:false)
                }
                .padding(.bottom, 16)
                .padding(.leading, 16)
                .padding(.trailing, 16)
                .popover(isPresented: $viewModel.isSharePressed) {
                    ActivityViewController(activityItems: [image ?? .init()])
                }
            }
            .background(.generalBackground)
            .padding(.top, 8)
            .onChange(of: self.puzzle) { newValue in
                self.viewModel.puzzle = self.puzzle
            }
        }
        .onAppear {
            viewModel.puzzle = self.puzzle
        }
    }
    
    var image:UIImage? {
        UIImage(named: puzzle.imageName) ?? originalImage
    }
}

