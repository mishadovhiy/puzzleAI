
import SwiftUI

struct DropPuzzleView: View {
    @State var indexPath:IndexPath
    @Binding var dragPosition: CGPoint
    @Binding var targetIndexPath:IndexPath?
    @Binding var croppedItem:CroppedPuzzleItem?
    @Binding var hint:Bool

    @Binding var draggingIndex:Int?
    @GestureState private var dragState = DragState.inactive
    let endDragging:(()->())?
    @State var isDragging:Bool = false
    let itemSize:CGSize
    @State var dragStartedLocally = false
    private var isSelected:Bool {
        targetIndexPath == indexPath
    }
    private func dropView(_ total:CGFloat) -> some View {
        HStack {
            if let image = croppedItem?.image {
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .opacity(isDragging ? 0 : 1)
                }
                .frame(width: total, height: total)
                .padding(hint ? 3 : 0)
            } else {
                Rectangle()
                    .fill(.clear)
            }
        }
        .background(hint ? .red.opacity(0.7) : .clear)
    }
        
    var body: some View {
        GeometryReader { geometry in
            let itemFrame = geometry.frame(in: .global)
            let superY = geometry.frame(in: .global).maxY - 148
            dropView(geometry.size.width)
                .border(.blueTint.opacity(0.3), width: isSelected ? 0.5 : 0)
                .onChange(of: self.dragPosition) { newPosition in
                    var dropFrame = geometry.frame(in: .global)
                    dropFrame.origin.x -= 20
                    dropFrame.origin.y -= 20
                    dropFrame.size.width += 40
                    dropFrame.size.height += 10
                    if croppedItem?.draggedID == nil || dragStartedLocally {
                        if dropFrame.contains(newPosition) {
                            self.targetIndexPath = self.indexPath
                        } else if self.targetIndexPath == self.indexPath, !dragStartedLocally {
                            self.targetIndexPath = nil
                        }
                    }
                    
                }
                .gesture(
                    DragGesture(minimumDistance: 40, coordinateSpace: .local)
                        .onChanged { value in
                            self.dragStartedLocally = true
                            self.isDragging = true
                            self.draggingIndex = croppedItem?.id
                            self.dragPosition = .init(x: itemFrame.minX + value.location.x, y: value.location.y + superY)
                        }
                        .updating($dragState, body: { (value, state, transition) in
                            state = .dragging(translation: value.translation)
                        })
                        .onEnded { value in
                            didEndDragging()
                        }
                )
                .onChange(of: dragState, perform: { value in
                    if value == .inactive {
                        didEndDragging()
                    }
                })
        }
        .frame(width:itemSize.width, height: itemSize.height)
    }
    
    func didEndDragging() {
        if !isDragging {
            return
        }
        isDragging = false
        croppedItem?.draggedID = nil
        endDragging?()
        dragStartedLocally = false
    }
}

