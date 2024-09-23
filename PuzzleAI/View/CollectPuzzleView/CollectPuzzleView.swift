
import SwiftUI
import AVFoundation

struct CollectPuzzleView: View {
    typealias ViewModel = CollectPuzzleViewModel
    @State var viewModel:ViewModel
    @GestureState private var magnifyBy = CGFloat(1.0)
    @Environment(\.dismiss) private var dismiss
    
    init(puzzle:PuzzleItem, startOverPressed:@escaping(_ newPuzzle:PuzzleItem)->()) {
        UINavigationController.canSetSwipeGesture = false
        self.viewModel = .init(puzzleName: puzzle.imageName, originalImage: nil, magnifyBy: 1)
        self.viewModel.startOverPressed = startOverPressed
        self.viewModel.magnifyBy = magnifyBy
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                contentView(proxy)
                if let _ = viewModel.draggingItem {
                    draggingItemView
                }
                ModalPopupView.configureCoint(.buyHint(viewModel.puzzleName), isPresenting: $viewModel.buyHintShowing, needAdditionalSpace: proxy.size.height)
                    .animation(.bouncy, value: viewModel.buyHintShowing)
                    .transition(.move(edge: .bottom))
            }
            .onChange(of: viewModel.buyHintShowing, perform: { newValue in
                if !newValue {
                    self.viewModel.updateFromDB()
                }
            })
            .onChange(of: viewModel.draggingIndex, perform: { newValue in
                viewModel.neverDragged = false
                DispatchQueue(label: "db", qos: .userInitiated).async {
                    DB.db.tutorials.draggedPuzzle = false
                }
            })
            .background(.generalBackground)
            .navigationBarBackButtonHidden(true)
            .fullScreenCover(isPresented: $viewModel.puzzleCompletionShowing) {
                PuzzleCompletionView(puzzle: isPuzzleCompletionPresenting, originalImage: self.viewModel.originalImage ?? (.init(name: viewModel.puzzleName) ?? .no))
                    .onAppear {
                        if !viewModel.puzzle.isClosed {
                            viewModel.errorPuzzleAudio?.play()
                        }
                    }
                    .onDisappear(perform: {
                        self.dismiss()
                    })
            }
            .onChange(of: viewModel.puzzleCompletionShowing, perform: { newValue in
                if newValue {
                    viewModel.dbUpdateCropped()
                }
            })
            .onAppear {
                viewModel.updateDBTrigger = {
                    DispatchQueue(label: "db", qos: .userInitiated).async {
                        if let puzzle = viewModel.sortedPuzzleDB {
                            DispatchQueue.main.async {
                                self.viewModel.updateFromDB(puzzle)
                            }
                        }
                    }
                }
                DispatchQueue(label: "db", qos: .userInitiated).async {
                    viewModel.neverDragged = DB.db.tutorials.draggedPuzzle
                }
                viewModel.puzzleCompletedAction = {
                    self.viewModel.puzzleCompletionShowing = true
                }
                if let image = UIImage(named: viewModel.puzzleName) {
                    viewModel.originalImage = image
                    DispatchQueue.init(label: "db", qos: .userInitiated).async {
                        let db = viewModel.puzzle
                        DispatchQueue.main.async {
                            self.viewModel.setImage(image, puzzle:db)

                        }
                    }
                } else if viewModel.puzzleName != "" {
                    DispatchQueue.init(label: "db", qos: .userInitiated).async {
                        let puzzle = viewModel.puzzle
                        self.viewModel.loadPuzzleBackgroundImage() { newImage in
                            DispatchQueue.main.async {
                                viewModel.imageLoaded(newImage, viewSize: proxy.size, puzzle: puzzle)

                            }
                        }
                    }
                } else {
                    viewModel.errorText = .init(title: "No image")
                }
                viewModel.backgroundAudio?.play()
            }
            .onDisappear {
                UINavigationController.canSetSwipeGesture = true
                viewModel.deinit()
            }
        }
    }
    
    private func contentView(_ proxy: GeometryProxy) -> some View {
        VStack {
            SuperNavigationView(title: "", needPaddings:true, rightButtons:  {
                navigationButtons
            }, needSeparetor:false)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    dropItemsView
                        .padding(.leading, viewModel.isFullScreen ? 0 : 16)
                        .padding(.trailing, viewModel.isFullScreen ? 0 : 16)
                    Spacer()
                }
                Spacer()
                VStack {
                    DefaultLine()
                    if #available(iOS 16.0, *) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            draggableItemsScrView(proxy.size)
                                .opacity(viewModel.isFullScreen ? 0 : 1)
                                .transition(.move(edge: .bottom))
                                .animation(.bouncy, value: viewModel.isFullScreen)
                        }
                        .scrollDisabled(viewModel.draggingIndex != nil)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            draggableItemsScrView(proxy.size)
                                .opacity(viewModel.isFullScreen ? 0 : 1)
                                .transition(.move(edge: .bottom))
                                .animation(.bouncy, value: viewModel.isFullScreen)
                        }
                    }
                }
                .overlay {
                    if viewModel.neverDragged {
//                        ZStack {
//                            Color.red
//                            Text("to start draging, press puzzle and move finger to the top")
//                                .setStyle()
//                        }
                        TutorialView(title: "to start draging, press puzzle and move finger to the top", position: .zero, okPressed: {
                            viewModel.neverDragged = true
                            DispatchQueue.init(label: "db", qos: .userInitiated).async {
                                DB.db.tutorials.draggedPuzzle = true
                            }
                        })
                        .disabled(true)
                            .offset(y:-100)
                    }
                }
            }
        }
        .padding(.bottom, viewModel.isNormalPuzzleWidth(proxy.size) ? 16 : 5)
    }
    
    private var draggingItemView: some View {
        GeometryReader { geometry in
            DraggablePuzzleView(dragPosition: $viewModel.dragPosition, draggingIndex: $viewModel.draggingIndex, hint: .constant(false), croppedItem: .constant(viewModel.draggingItem), itemSize: viewModel.itemSize, endDragging: nil)
                .position(x:viewModel.dragPosition.x, y:viewModel.dragPosition.y)
                .opacity(1)
                .animation(.easeInOut(duration: 0.3), value: viewModel.draggingItem != nil)
                .transition(.opacity)
                .shadow(color:.black, radius: 10, x: 2, y: 4)
        }
    }
    
    var hintOverlay: some View {
        VStack {
            Text(viewModel.hints == 0 ? "+" : "\(viewModel.hints)")
                .foregroundColor((Color(uiColor: .init(named: "titleColor") ?? .red)))
                .font(UIFont.custom(size: 12))
                .lineLimit(1) .minimumScaleFactor(0.2)
            
        }
        .frame(width: 14, height: 14)
        .background(.blueTint)
        .cornerRadius(50)
        .padding(1)
    }
    
    private func navigationButton(key:CollectPuzzleViewModel.NavigationButtons, isSelected:Bool) -> some View {
        Image(key.image(isActive: isSelected))
            .foregroundStyle(isSelected ? .blueTint : (Color(uiColor: .init(named: "titleColor") ?? .red)))
            .frame(maxWidth:.infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .padding(.top, 3)
            .padding(.bottom, 3)
            .disabled(key == .hint && !viewModel.hintEnabled)
            .opacity(key == .hint && !viewModel.hintEnabled ? 0.2 : 1)
            .overlay {
                if key == .hint {
                    VStack {
                        HStack {
                            Spacer()
                            hintOverlay
                        }
                        Spacer()
                    }
                }
            }
    }
    
    private var navigationButtons:some View {
        HStack {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 50)
                    .stroke(.descriptionText, style: .init(lineWidth: 0.5))
                HStack {
                    ForEach(0..<CollectPuzzleViewModel.NavigationButtons.allCases.count, id: \.self) {
                        let key = CollectPuzzleViewModel.NavigationButtons.allCases[$0]
                        let value = viewModel.isNavigationActive(for: key)
                        if key == .preview {
                            ZStack {
                                navigationButton(key: key, isSelected: value)
                                    .disabled(true)
                                TouchTrackingView { began in
                                    viewModel.setNavigationActive(for: key, newValue: began)
                                } onTouchMoved: {
                                    
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                
                            }
                        } else {
                            Button(action: {
                                viewModel.setNavigationActive(for: key, newValue: !value)
                            }, label: {
                                navigationButton(key: key, isSelected: value)
                            })
                        }
                        
                    }
                }
                .frame(width: 42 * CGFloat(CollectPuzzleViewModel.NavigationButtons.allCases.count))
            }
        }
    }
    
    private func draggableItemView(_ draggbleItem:CroppedPuzzleItem?, item:CroppedPuzzleItem, viewSize:CGSize) -> some View {
        let isNormalWidth = viewModel.isNormalPuzzleWidth(viewSize)
        return VStack {
            Spacer().frame(height: isNormalWidth ? 23 : 5)
            DraggablePuzzleView(dragPosition: $viewModel.dragPosition, draggingIndex: $viewModel.draggingIndex, hint: .constant(viewModel.currentHint?.id == item.id), croppedItem: .constant(draggbleItem), itemSize: viewModel.itemSize * (isNormalWidth ? 1 : 0.8), endDragging: {
                withAnimation(.easeInOut(duration: 0.13)) {
                    viewModel.endDragging()
                }
            })
        }
    }
    
    private func draggableItemsScrView(_ viewSize:CGSize) -> some View {
        HStack() {
            Spacer()
                .frame(width: 16)
            ForEach(viewModel.draggbleItems, id:\.id) { item in
                HStack {
                    if let draggableItem = viewModel.draggbleItems.first(where: {$0.id == item.id}) {
                        draggableItemView(draggableItem, item: item, viewSize: viewSize)
                    }
                    Spacer()
                        .frame(width: 21)
                }
                .disabled(viewModel.isNavigationActive(for: .preview))
            }
        }
    }
    
    var zoomPanel:some View {
        HStack(spacing:10) {
            VStack {
                Spacer()
                Button(action: {
                    viewModel.scaleMinus()
                }, label: {
                    Text("-")
                        .foregroundColor(.generalBackground)
                        .font(UIFont.custom(size: 16, width:.semibold))
                })
                .frame(width: 26, height: 26)
                .tint(.generalBackground)
                .background(viewModel.canZoomOut ? .blueTint : .descriptionText)
                .disabled(!viewModel.canZoomOut)
                .cornerRadius(50)
                Spacer()
            }
            Text("\(viewModel.zoomPercent)%")
                .setStyle(.middle)
            VStack {
                Spacer()
                Button {
                    viewModel.scalePlus()
                } label: {
                    Text("+")
                        .foregroundColor(.generalBackground)
                        .font(UIFont.custom(size: 16, width: .semibold))
                }
                .frame(width: 26, height: 26)
                .tint(.generalBackground)
                .background(viewModel.canZoomIn ? .blueTint : .descriptionText)
                .disabled(!viewModel.canZoomIn)
                .cornerRadius(50)
                Spacer()
            }
        }
    }
    
    var dropParameterButtons: some View {
        ZStack {
            HStack {
                Spacer()
                zoomPanel
                Spacer()
            }
            .frame(height: 40)
            HStack {
                Spacer()
                Button {
                    viewModel.isFullScreen.toggle()
                } label: {
                    Image(.fullScreen)
                }
                .tint((Color(uiColor: .init(named: "titleColor") ?? .red)))
                .frame(width: 40, height: 40)
                
            }
            .frame(height: 40)
        }
        .frame(height: 40)
    }
    
    private var dropItemsView:some View {
        GeometryReader { geometry in
            let imageWidth = viewModel.imageWidth(geometry: geometry)
            let position = viewModel.offsetResult(max: .init(width: imageWidth, height: imageWidth))
            VStack(spacing:8) {
                Spacer()
                HStack(alignment:.center) {
                    puzzleDropViews(geometrySize: geometry.size, imageWidth: imageWidth, position: position)
                        .onAppear {
                            viewModel.viewSizeChanged(viewSize: geometry.size)
                        }
                        .clipShape(Rectangle())
                        .contentShape(Rectangle())
                }
                .frame(width: imageWidth, height: imageWidth)
                dropParameterButtons
                    .disabled(viewModel.draggingIndex != nil)
                Spacer()
                    .opacity(!viewModel.isFullScreen ? 1 : 0)
                    .transition(.slide)
                    .animation(.bouncy, value: viewModel.isFullScreen)
            }
        }
    }
    
    private func puzzleDropViews(geometrySize:CGSize, imageWidth:CGFloat, position:CGSize) -> some View {
        return puzzleDropStack(geometrySize: geometrySize)
            .frame(width: imageWidth, height: imageWidth, alignment: .center)
            .scaleEffect(viewModel.scaleResult)
            .position(x:position.width,y:position.height)
            .border(.descriptionText, width: 1)
            .background(Color(uiColor: .init(named: "containerColor")!))
            .gesture(
                MagnificationGesture().onChanged({ new in
                    viewModel.scale *= new
                })
                .simultaneously(
                    with: DragGesture(minimumDistance: 0)
                        .onChanged({ value in
                            viewModel.offset = viewModel.handleOffsetChange(offset: value.translation)
                        })
                        .onEnded({ _ in
                            viewModel.lastOffset = viewModel.offset
                        })
                )
            )
    }
    
    private func backgroundImage(_ original:UIImage,
                                 geometrySize:CGSize) -> some View {
        VStack {
            Image(uiImage: original)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .scaledToFit()
                .scaleEffect(viewModel.isPuzzleType == .puzzle ? 1 : 1)
                .opacity(viewModel.isNavigationActive(for: .preview) ? 0.4 : 0)
        }
    }
    
    private func puzzleDropStack(geometrySize:CGSize) -> some View  {
        let imageWidth = geometrySize.height >= geometrySize.width ? geometrySize.width : geometrySize.height
        let itemSize:CGSize = .init(width: imageWidth / CGFloat(viewModel.numberOfRows), height: imageWidth / CGFloat(viewModel.numberOfRows))
        
        let spaces = viewModel.stackSpaces(itemSize.width) * -1
        
        return ZStack {
            HStack {
                if let original = viewModel.originalImageHolder ?? viewModel.originalImage {
                    backgroundImage(original, geometrySize: geometrySize)
                } else if viewModel.isLoading {
                    LoadingView(isLotille: nil)
                } else {
                    NoDataView(text:viewModel.errorText?.title ?? "Unknown error", needImage: false)
                }
            }
            .frame(width: imageWidth, height: imageWidth)
            VStack(spacing:spaces) {
                ForEach(0..<viewModel.numberOfSections, id:\.self) { section in
                    dropItemView(spaces: spaces, section: section, size: itemSize)
                }
            }
            .frame(width: imageWidth, height: imageWidth)
            .scaleEffect(viewModel.isPuzzleType == .puzzle ? 1.45 : 1)
        }
        
    }
    
    private func dropItemView(spaces:CGFloat, section: Int, size:CGSize) -> some View {
        HStack(spacing:spaces) {
            ForEach(0..<viewModel.numberOfRows, id:\.self) { row in
                DropPuzzleView(indexPath:.init(row: row, section: section), dragPosition: $viewModel.dragPosition, targetIndexPath: $viewModel.targetIndexPath, croppedItem: .init(get: {
                    viewModel.croppedItem(row, section)
                }, set: {
                    if let newValue = $0 {
                        viewModel.updateCropped(row, section, with: newValue)
                    }
                }), hint: .constant(viewModel.currentHint?.id == row.index(section, numberOfRows: viewModel.numberOfRows)), draggingIndex: $viewModel.draggingIndex, endDragging: {
                    withAnimation(.easeInOut(duration: 0.13)) {
                        viewModel.endDragging()
                    }
                }, itemSize: size)
                .disabled(viewModel.isNavigationActive(for: .preview))
            }
        }
    }
    
    var isPuzzleCompletionPresenting:Binding<PuzzleItem> {
        .init(get: {
            viewModel.puzzle
        }, set: {_ in
            self.viewModel.dbUpdateCropped()
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute:  {
                self.viewModel.startOverPressed?(viewModel.puzzle)
                self.dismiss()
            })
        })
    }
}
