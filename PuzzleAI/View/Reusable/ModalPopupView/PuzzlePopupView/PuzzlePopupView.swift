
import SwiftUI

struct PuzzlePopupView: View {
    @Binding var parentData:ModalPopupViewModel.ModalPopupData
    @Binding var isPresenting:Bool
    @Binding var isCollectPuzzlePresenting:PuzzleItem?
    @State var viewModel:PuzzlePopupViewModel = .init()
    @Binding var reloadContentID:UUID
    @State var presentationCompleted:Bool = false
    
    var body: some View {
        VStack() {
            Spacer()
            HStack(alignment:.center) {
                PuzzleItemView(image: .constant(viewModel.puzzle), presentingPuzzlePopup: .constant(nil))
                    .frame(width:220, height: 220)
            }
            if viewModel.puzzle.isStarted {
                VStack {
                    Text("Pieces")
                        .setStyle(.descriptionSmall)
                    HStack {
                        Text("х")
                            .setStyle(.description)
                        Text("\(viewModel.puzzle.totalPeaces?.piecesCount ?? -1)")
                            .setStyle(.bigDescription)
                    }
                    Spacer().frame(height: 4)
                }
            }
            CointView(coint: .constant(viewModel.coint), labelText: viewModel.cointTitle)
            Spacer()
                .frame(minHeight: 30, maxHeight: 50)
            VStack {
                LoadingButton(data: .init(title: viewModel.primaryButtonTitle, pressed: {
                    viewModel.todifficulty()
                    reloadContentID = .init()
                }), nextEnabled:viewModel.nextEnabled, canAnimate: true, stopAnimation: $viewModel.stopButtonAnimations)
                .id(viewModel.loadingButtonReloadID)
                
                if viewModel.puzzle.isStarted {
                    LoadingButton.configure(data: .init(title: viewModel.secondaryButtonTitle, type:.secondary, pressed: {
                        viewModel.toStartOver()
                    }))
                }
            }
            .frame(maxWidth: .infinity)
            .opacity(presentationCompleted ? 1 : 0)
            .animation(.bouncy, value: presentationCompleted)
            .transition(.move(edge: .bottom))
        }
        .alert(viewModel.secondaryButtonTitle, isPresented: $viewModel.isStartOverAlertPresenting) {
            Button(viewModel.secondaryButtonTitle, role: .destructive) {
                viewModel.isStartOverAlertPresenting = false
                viewModel.toStartOverConfirmed()
            }
            Button("Cancel", role: .cancel) {
                viewModel.isStartOverAlertPresenting = false
            }
        } message: {
            Text(viewModel.alertDescription)
        }
        .onChange(of: isPresenting, perform: { newValue in
            viewModel.stopButtonAnimations = true
            viewModel.loadingButtonReloadID = .init()
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(350), execute: {
                    presentationCompleted = true
                })
            } else {
                animate {
                    presentationCompleted = false
                }
            }
        })
        .onAppear {
            viewModel.toDifficultyAction = {
                isCollectPuzzlePresenting = viewModel.puzzle
            }
            viewModel.dataUpdated = { new in
                animate(.bouncy, {
                    parentData = .init(difficulty: new.difficulty)
                }, completion: {
                    reloadContentID = .init()
                })
            }
            viewModel.parentData = parentData
            
        }
        .onChange(of: parentData) { newValue in
            viewModel.parentData = newValue
        }
    }
}

