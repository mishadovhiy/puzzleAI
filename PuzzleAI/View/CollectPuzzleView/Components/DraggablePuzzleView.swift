
import SwiftUI
struct DraggablePuzzleView: View {
    @Binding var dragPosition: CGPoint
    @Binding var draggingIndex:Int?
    @Binding var hint:Bool
    @Binding var croppedItem:CroppedPuzzleItem?
    @GestureState private var dragState = DragState.inactive
    let itemSize:CGFloat
    let endDragging:(()->())?
    
    var body: some View {
        if let _ = croppedItem?.image {
            if canDrag {
                resultImageView
                    .frame(width: itemSize, height: itemSize)
                    .onChange(of: dragState) { newIsActiveValue in
                        if newIsActiveValue == .inactive {
                            endDragging?()
                        }
                    }
            } else {
                imageView()
                    .opacity(1)
            }
        } else {
            Text("?")
        }
    }
    
    var canDrag:Bool {
        endDragging != nil && croppedItem?.draggedID == nil
    }
    
    func imageView() -> some View {
        ZStack {
            Image(uiImage: croppedItem?.image ?? .Test._1)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: itemSize, height: itemSize)
                .border(hint ? .red : .clear, width: hint ? 2 : 0)
                .clipped(antialiased: false)
//            LoadingView(isLotille: .longPress, size: itemSize / 2, forceHideImage: true)
//                .frame(width: itemSize / 2, height: itemSize / 2)
//                .scaledToFit()
//                .offset(y: 40)
//                .scaleEffect(0.3)
//                .aspectRatio(contentMode: .fit)
//                .opacity(hint ? 0.4 : 0)
        }
    }
    
    var resultImageView:some View {
        GeometryReader { geometry in
            let itemFrame = geometry.frame(in: .global)
            let drfaultFrame = geometry.frame(in: .local)
            let defaultFrameSize:CGPoint = .init(x: drfaultFrame.midX, y: drfaultFrame.midY)
            
            let superY = geometry.frame(in: .global).maxY - 148
            
            return imageView()
                .position(croppedItem?.id ==  draggingIndex && draggingIndex != nil ? .init(x: dragPosition.x - itemFrame.minX, y: dragPosition.y) : defaultFrameSize)
                .opacity(croppedItem?.id ==  draggingIndex && draggingIndex != nil && canDrag ? 0 : 1)
                .gesture(
                    DragGesture(minimumDistance: 20, coordinateSpace: .local)
                        .onChanged { value in
                            self.draggingIndex = croppedItem?.id
                            self.dragPosition = .init(x: itemFrame.minX + value.location.x, y: value.location.y + superY)
                        }
                        .updating($dragState, body: { (value, state, transition) in
                            state = .dragging(translation: value.translation)
                        })
                        .onEnded { value in
                            endDragging?()
                        }
                )
        }
    }
}
