
import SwiftUI

struct ModalPopupView: View {
    @Binding var popupData:ModalPopupViewModel.ModalPopupData
    @State var viewModel:ModalPopupViewModel = .init()
    @Binding var isPresenting:Bool
    @Binding var isCollectPuzzlePresenting:PuzzleItem?
    var cointsType:CointsPopupView.CointsPopupViewModel.CointsType? = nil
    var nextPressed:Binding<Bool>? = nil
    var needAdditionalSpace:CGFloat? = nil
    @State var forceHideBackground:Bool = false
    @State var reloadContentID:UUID = .init()

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing:-10) {
                backgroundView(geometry)
                ZStack {
                    contentBackground
                    generalContentView(geometry.size)
                        .frame(maxWidth: .infinity)
                }
                .background(.generalBackground)
                .cornerRadius(16)
                .onChange(of: popupData) { newValue in
                    animate(.bouncy, {
                        viewModel.popupDataUpdateble = newValue
                    }, completion: {
                        reloadContentID = .init()
                    })
                }
                .onChange(of: isPresenting) { newValue in
                    if viewModel.popupDataUpdateble.puzzle == nil && viewModel.popupDataUpdateble.difficulty == nil {
                        viewModel.popupDataUpdateble = popupData
                    }
                    viewModel.cointsType = cointsType
                    reloadContentID = .init()
                }
            }
            .background(.clear)
        }
    }
}

fileprivate extension ModalPopupView {
    func generalContentView(_ geometrySize:CGSize) -> some View {
        HStack {
            Spacer()
            VStack {
                HStack(alignment:.top) {
                    Text(viewModel.screenTitle)
                        .setStyle(.title)
                    Spacer()
                    closeButton
                }
                if viewModel.isSmallDevice(geometrySize) {
                    ScrollView(.vertical, showsIndicators: false) {
                        contentView(geometrySize)
                    }
                    .frame(minHeight: geometrySize.height * 0.74)
                } else {
                    contentView(geometrySize)
                        .animation(.bouncy, value: isPresenting)
                        .transition(.move(edge: .bottom))
                }
            }
            .padding(viewModel.paddings)
            Spacer()
        }
        .background(.generalBackground)
        .offset(y:1)
    }

    func contentView(_ geometrySize:CGSize) ->  some View {
        HStack {
            if let cointsType = viewModel.cointsType {
                CointsPopupView(viewModel: .init(type: cointsType), isPresenting: $isPresenting, nextPressed: nextPressed, geometrySize: geometrySize)
            } else if viewModel.popupDataUpdateble.difficulty != nil || viewModel.popupDataUpdateble.puzzle?.imageName == "" {
                DifficultyPuzzleView(puzzle: viewModel.popupDataUpdateble.difficulty ?? (viewModel.popupDataUpdateble.puzzle ?? .init(imageName: "")), isPresenting: $isPresenting, isCollectPuzzlePresenting: $isCollectPuzzlePresenting)
            } else if viewModel.popupDataUpdateble.puzzle?.imageName != "" {
                PuzzlePopupView(parentData: $viewModel.popupDataUpdateble, isPresenting: $isPresenting, isCollectPuzzlePresenting: $isCollectPuzzlePresenting, reloadContentID: $reloadContentID)
            } else {
                CointsPopupView(viewModel: .init(type: viewModel.cointsType ?? .buyCoint), isPresenting: $isPresenting, nextPressed: nextPressed, geometrySize: geometrySize)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Component View
    func backgroundView(_ viewSize:GeometryProxy) ->  some View {
        let safeArea = viewSize.safeAreaInsets.top + viewSize.safeAreaInsets.bottom + (needAdditionalSpace ?? 0)
        
        return Rectangle()
            .fill(.generalBackground.opacity(0.5))
            .animation(.easeInOut, value: isPresenting)
            .transition(.opacity)
            .disabled(!isPresenting)
            .opacity(isPresenting ? (forceHideBackground ? 0 : 1) : 0)
            .onTapGesture {
                closePressed()
            }
            .frame(height: isPresenting ? .none : ((viewSize.size.height * 1.1) + safeArea + 10))
    }
    
    var contentBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.generalBackground)
            .border(Color(uiColor: .init(named: "containerColor")!), width: 2)
    }
    
    var closeButton:some View {
        Button(action: {
            closePressed()
        }, label: {
            Image(.close)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(9)
        })
        .closeStyle
    }
    
    func closePressed() {
        animate(.easeInOut,{
            forceHideBackground = true
        })
        Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { _ in
            animate(.easeInOut, {
                isPresenting = false
            }, completion: {
                forceHideBackground = false
            })
        }
    }
}


extension ModalPopupView {
    static func configureCoint(_ type:ModalPopupView.CointsPopupView.CointsPopupViewModel.CointsType, isPresenting:Binding<Bool>, needAdditionalSpace:CGFloat? = nil) -> ModalPopupView {
        return .init(popupData: .constant(.init()), isPresenting: isPresenting, isCollectPuzzlePresenting: .constant(nil), cointsType: type, needAdditionalSpace: needAdditionalSpace, reloadContentID: .init())
    }
}

