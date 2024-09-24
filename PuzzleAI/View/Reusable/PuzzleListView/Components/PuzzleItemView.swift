//
//  PuzzleItemView.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import SwiftUI

struct PuzzleItemView: View {
    @Binding var image:PuzzleItem
    @State var loadedImage:UIImage?
    @State var isList:Bool = false
    @Binding var presentingPuzzlePopup:PuzzleItem?
    @State var reloadUI:(()->())? = nil
    @State var viewModel:PuzzleItemViewModel = .init()
    var isAiViewType:Bool = false
    
    var body: some View {
        VStack {
            if let image = (imageNamed ?? loadedImage) {
                imageView(image)
            } else {
                puzzleView
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .cornerRadius(18)
        .shadow(color: Color(uiColor: viewModel.imageShadowColor), radius: 4, y:2)
        .shadow(color: Color(uiColor: viewModel.imageShadowColor), radius: 2, y: 1)
        .onAppear {
            checkImage(image.imageName)
        }
        .onChange(of: image, perform: { newValue in
            checkImage(newValue.imageName)
        })
        .onTapGesture {
            animate {
                presentingPuzzlePopup = image
            }
        }
        .onLongPressGesture {
            if image.aIGenerationType == .byUser {
                viewModel.deleteAlertPresenting = true
            }
        }
        .alert("Delete puzzles", isPresented: $viewModel.deleteAlertPresenting) {
            Button("Delete", role: .destructive) {
                self.deleteAiPressed()
            }
            Button("Cancel", role: .cancel, action: {
                viewModel.deleteAlertPresenting = false
            })
        } message: {
            Text(viewModel.alertConfirmDeletionText)
        }
        .onChange(of: viewModel.deleteAlertPresenting) { newValue in
            if newValue {
                DispatchQueue(label: "db", qos: .userInitiated).async {
                    DB.db.tutorials.needDeleteAiTutorial = false
                }
            }
        }
    }
    
    var imageNamed:UIImage? {
        return .init(name: image.imageName)
    }
    
    func imageView(_ image:UIImage) -> some View {
        ZStack(content: {
            Image(uiImage: image)
                .resizable()
                .interpolation(.low)
                .scaledToFit()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: .infinity)
                .clipped()
            HStack {
                if self.image.isCreatedByAI && !isAiViewType {
                    VStack {
                        Image(.aiGenerated)
                            .resizable()
                            .frame(width: 40, height: 40)
                        Spacer()
                    }
                    Spacer()
                }
                if self.image.isStarted, self.image.progressInt > 0 {
                    zoomPercentView
                }
            }
            .padding(12)
            if isList {
                if self.image.isLocked {
                    ZStack {
                        Color(.black.withAlphaComponent(0.6))
                        Image(.locker)
                    }
                }
            }
        })
    }
    
    var zoomPercentView: some View {
        VStack(alignment:.trailing) {
            HStack(alignment:.top) {
                VStack {
                    Text("\(self.image.progressInt)%")
                        .setStyle(.defaultBoldBlue)
                }
                .padding(.leading, 8)
                .padding(.trailing, 8)
                .padding(.top, 3)
                .padding(.bottom, 3)
                .background((Color(uiColor: .init(named: "titleColor") ?? .red)))
                .cornerRadius(30)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    private var puzzleView:some View {
        ZStack(content: {
            VStack {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundColor(.descriptionText)
                    .background(content: {
                        Color.clear
                    })
            }
            VStack(content: {
                if image.imageName == "" {
                    Image(.no)
                        .foregroundColor(.descriptionText)
                }
                Text(viewModel.createAIContainerTitle(image.imageName))
                    .setStyle(.description)
            })
        })
        .frame(minHeight: 120)
    }
    @State var loadedImageName:String = ""
    // - MARK: private methods
    private func checkImage(_ imageName:String) {
        if imageName != loadedImageName {
            self.loadedImage = .noList
            viewModel.checkImage(imageName, isList: isList) { newImage in
                self.loadedImageName = imageName
                self.loadedImage = newImage
            }
        }
    }
    
    private func deleteAiPressed() {
        viewModel.deleteAiPressed(image: self.image) {
            reloadUI?()
        }
    }
}

