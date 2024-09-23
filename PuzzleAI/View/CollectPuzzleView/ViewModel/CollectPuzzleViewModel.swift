
import SwiftUI

struct CollectPuzzleViewModel {
    mutating func `deinit`() {
        [backgroundAudio, dropAudio, errorPuzzleAudio].forEach {
            $0?.stop()
            $0?.audioPlayer = nil
        }
        self.originalImage = nil
        self.needUpdatePuzzleDB = false
        self.croppedImages.removeAll()
        self.originalImageHolder = nil
        self.croppedDB.removeAll()
    }
    var neverDragged = true
    var hints: Int = 0
    var puzzleCompletedAction:(()->())?
    var errorText:MessageContent?
    var isLoading:Bool {
        if errorText != nil {
            return false
        }
        if originalImage != nil {
            return false
        }
        return true
    }
    var startOverPressed:((_ newPuzzle:PuzzleItem)->())?
    var backgroundAudio: AudioPlayerManager? = .init(type: .gameMusic)
    var dropAudio: AudioPlayerManager? = .init(type: .puzzleDrop)
    var errorPuzzleAudio: AudioPlayerManager? = .init(type: .puzzleError)
    let puzzleName:String
    var originalImage:UIImage? = nil
    var originalSize:CGSize = .zero
    var difficulty:PuzzleItem.Difficulty = .easy
    var currentHint:CroppedPuzzleItem?
    var isCompleted:Bool {
        return croppedDB.isCompleted()
    }
    var hintEnabled = true
    var puzzleCompletionShowing:Bool = false
    var buyHintShowing:Bool = false
    private var navigationButtons:[NavigationButtons:Bool] = [:]
    
    var isPuzzleType:PuzzleItem.PuzzleType = .puzzle
    var numberOfRows:Int{ difficulty.numberOfRows }
    var numberOfSections:Int{ difficulty.numberOfSections }
    private let minPuzzleScale:CGFloat = 1
    var scale: CGFloat = 1.0 {
        didSet {
            if scaleResult != scale {
                scale = scaleResult
            }
        }
    }
    var lastOffset: CGSize = .zero
    var offset: CGSize = .zero
    var croppedDB:[CroppedPuzzleItem] = []
    var dragPosition = CGPoint.zero
    var targetIndexPath: IndexPath?
    var draggingIndex:Int?
    let itemSize:CGFloat = 80
    private var needUpdatePuzzleDB:Bool = false
    var originalImageHolder:UIImage? = nil
    
    static let puzzleMarginDivider:CGFloat = 5
    static func margin(itemWidth:CGFloat) -> CGFloat {
        return itemWidth / puzzleMarginDivider
    }
    var magnifyBy:CGFloat
    init(puzzleName: String, originalImage: UIImage?, magnifyBy:CGFloat) {
        self.puzzleName = puzzleName
        self.magnifyBy = magnifyBy
        if let originalImage {
            self.setImage(originalImage)
        }
    }
    
    mutating func setImage(_ image:UIImage, puzzle:PuzzleItem? = nil) {
        self.originalImage = image
        self.updateFromDB(puzzle)
    }
    
    var puzzle:PuzzleItem {
        DB.db.puzzleList.first(where: {$0.imageName == puzzleName}) ?? .init(imageName: puzzleName)
    }
    
    mutating func updateFromDB(_ puzzle:PuzzleItem? = nil) {
        let db = puzzle ?? self.puzzle
        self.croppedDB = db.completedPeaces
        self.isPuzzleType = db.type
        self.difficulty = db.totalPeaces ?? .easy
        self.hints = db.hints

    }
    
    var croppedImages:[CroppedPuzzleItem] = [] {
        didSet {
            if needUpdatePuzzleDB {
                dbUpdateCropped()
            } else {
                needUpdatePuzzleDB = true
            }
        }
    }
    
    var draggbleItems:[CroppedPuzzleItem] {
        let items = croppedImages.filter({$0.draggedID == nil})
        if navigationButtons[.crop] ?? false {
            return items.filter({$0.isCornered})
        }
        return items
    }
    
    mutating func generateHint() {
        if hints <= 0 {
            buyHintShowing = true
        } else {
            hintEnabled = false
            let name = puzzleName
            hints -= 1
            let hints = hints
            let action = updateDBTrigger
            currentHint = emptyItems.randomElement() ?? croppedImages.filter({$0.draggedID != $0.id}).randomElement()
            DispatchQueue(label: "db", qos: .userInitiated).async {
                for i in 0..<DB.db.puzzleList.count {
                    if DB.db.puzzleList[i].imageName == name {
                        DB.db.puzzleList[i].hints = hints
                    }
                }
                DispatchQueue.main.async {
                    action?()
                }
            }
        }
    }
    var updateDBTrigger:(()->())?
    var emptyItems:[CroppedPuzzleItem] {
        return croppedImages.filter({$0.draggedID == nil})
    }
    
    var sortedPuzzleDB:PuzzleItem? {
        DB.db.puzzleList.filter({$0.imageName == puzzleName}).sorted(by: {$0.hints >= $1.hints}).first
    }
    mutating func viewSizeChanged(viewSize:CGSize, puzzle:PuzzleItem? = nil) {
        if viewSize == .zero {
            return
        }
        self.updateFromDB(puzzle)
        guard let originalImage else { return }
        if isPuzzleType == .puzzle {
            scale = minPuzzleScale
        }
        needUpdatePuzzleDB = false
        let imageWidth = viewSize.height >= viewSize.width ? viewSize.width : viewSize.height
        self.originalSize = .init(width: imageWidth, height: imageWidth)
        self.originalImage = originalImage.changeSize(newWidth: imageWidth)
        generateImages(viewSize: viewSize)
        needUpdatePuzzleDB = true
    }
    
    mutating func endDragging(forcePlay:Bool = false) {
        if targetIndexPath != nil || forcePlay {
            self.dropAudio?.play()
        }
        guard let targetID = targetIndexPath?.row.index(targetIndexPath?.section ?? 0, numberOfRows: difficulty.numberOfRows),
              let draggingIndex else {
            targetIndexPath = nil
            self.draggingIndex = nil
            self.dragPosition = .zero
            return
        }
//        if targetID != draggingIndex {
//            errorPuzzleAudio?.play()
//        } else {
            for i in 0..<croppedImages.count {
                if croppedImages[i].id == draggingIndex,
                   croppedImages[i].draggedID == nil {
                    croppedImages[i].draggedID = targetID
                }

             }
      //  }

        targetIndexPath = nil
        self.draggingIndex = nil
        dragPosition = .zero
        
           
    }

    mutating private func generateImages(viewSize:CGSize) {
        guard let originalImage else { return }
        var new = croppedImages
        let holder = croppedDB
        new.removeAll()
        if isPuzzleType == .puzzle {
            self.originalImageHolder = originalImage
            self.originalImage = originalImage
        } else {
            originalImageHolder = nil
        }
        for section in 0..<numberOfSections {
            for index in 0..<numberOfRows {
                let image = generatedImage(index, section, imageSize: self.originalSize)
                if let image {
                    let id = index.index(section, numberOfRows: numberOfRows)
                    new.append(.init(id: id, draggedID: holder.first(where: {$0.draggedID != nil && $0.id == id})?.draggedID, image: image.image, ignoreSides: image.ignore))
                }
            }
        }
        croppedImages = new.shuffled()
    }
    
    func stackSpaces(_ itemWidth:CGFloat) -> CGFloat {
        if isPuzzleType == .puzzle {
            return CollectPuzzleView.ViewModel.margin(itemWidth: itemWidth) * 2
        } else {
            return 0
        }
    }
    
    func itemWidth(_ total:CGFloat) -> CGFloat {
        total / CGFloat(difficulty.numberOfRows)
    }
    
    mutating func generatedImage(_ i:Int,
                                 _ section:Int,
                                 imageSize:CGSize) -> (image:UIImage?, ignore:[PuzzleMaskModel.IgnoreSide])? {
        guard let originalImage else { return nil}
        let size:CGSize = .init(width: itemWidth(imageSize.width), height: imageSize.height / CGFloat(difficulty.numberOfSections))
        let margin = stackSpaces(size.width)
        let x = size.width * CGFloat(i) - CGFloat(margin * CGFloat(i))
        let y = size.height * CGFloat(section) - CGFloat(margin * CGFloat(section))
        let origin:CGPoint = .init(x: x, y: y)
        var ignore:[PuzzleMaskModel.IgnoreSide] = []
        if section == 0 {
            ignore.append(.top)
        }
        if section == numberOfSections - 1 {
            ignore.append(.bottom)
        }
        if i == numberOfRows - 1 {
            ignore.append(.right)
        }
        if i == 0 {
            ignore.append(.left)
        }
        let totalSize:CGSize = .init(width: imageSize.width - (margin * 4), height: imageSize.height - (margin * 4))
        if isPuzzleType == .puzzle {
            let image = PuzzleMaskModel.puzzleImage(originalImage: originalImage, itemSize: size, totalSize: totalSize, offset: origin,exept: ignore, inside: .init(i.index(section, numberOfRows: numberOfRows)))
            return (image, ignore)
            
        } else {
            let image = originalImage.changeSize(newWidth: imageSize.width).cropped(to: .init(origin: origin, size: size))
            return (image, ignore)
        }
    }
    
    var draggingItem:CroppedPuzzleItem? {
        if let draggingIndex {
            return croppedItem(draggingIndex, isDragging: false) ?? croppedImages.first(where: {$0.id == draggingIndex})
        }
        return nil
    }
    
    func croppedItem(_ index:Int, isDragging:Bool = false) -> CroppedPuzzleItem? {
        return croppedImages.first(where: {
            if isDragging && $0.draggedID != nil {
                return isDragging ? $0.draggedID == index : $0.id == index
            } else if isDragging {
                return false
            } else if !isDragging && $0.draggedID != nil {
                return false
            }
            return isDragging ? $0.draggedID == index : $0.id == index
        })
    }
    
    func croppedItem(_ row:Int, _ section:Int) -> CroppedPuzzleItem? {
        self.croppedItem(row.index(section, numberOfRows: numberOfRows), isDragging: true)
    }
    
    mutating func updateCropped(_ row:Int, _ section:Int, with newValue:CroppedPuzzleItem) {
        let item =             self.croppedItem(row.index(section, numberOfRows: numberOfRows), isDragging: true)
        for i in 0..<self.croppedImages.count {
            if croppedImages[i].id == item?.id {
                croppedImages[i] = newValue
            }
        }
    }
    
    mutating func imageLoaded(_ newImage:UIImage?, viewSize:CGSize, puzzle:PuzzleItem? = nil) {
        if let image = newImage {
            setImage(image, puzzle: puzzle)
            viewSizeChanged(viewSize: viewSize, puzzle: puzzle)
        } else {
            errorText = .init(title: "Image not saved on the device")
        }
    }
    
    func loadPuzzleBackgroundImage(completion:@escaping(_ newImage:UIImage?)->()) {
        FileManagerModel().load(imageName: puzzleName, quality: .original) {
            completion($0)
        }
    }
    
    func offsetResult(max:CGSize) -> CGSize {
        var offset = offset
        offset.width += max.width / 2
        offset.height += max.height / 2
        let maxWidth = max.width / 2 * scaleResult
        let maxHeight = max.height / 2 * scaleResult
        
        if offset.width >= maxWidth {
            offset.width = maxWidth
        }
        if offset.height >= maxHeight {
            offset.height = maxHeight
        }
        if scaleResult > 1 {
            let minWidth = max.width - ((max.width * scaleResult) / 2)
            let minHeight = max.height - ((max.height * scaleResult) / 2)
            if minWidth > offset.width {
                offset.width = minWidth
            }
            if minHeight > offset.height {
                offset.height = minHeight
            }
        } else {
            offset.height = maxHeight
            offset.width = maxWidth
        }
#if DEBUG
        print("offset: ", offset, " max: ", max)
#endif
        return offset
    }
    
    var zoomMax:CGFloat {
        isPuzzleType == .puzzle ? 2.5 : 2.5
    }
    
    var zoomMin:CGFloat {
        isPuzzleType == .puzzle ? minPuzzleScale : 1
    }
    
    func isNormalPuzzleWidth(_ geometrySize:CGSize) -> Bool {
        geometrySize.height >= geometrySize.width * 1.5
    }
    
    func imageWidth(geometry:GeometryProxy) -> CGFloat {
        let width = geometry.size.height >= geometry.size.width ? geometry.size.width : geometry.size.height
        let cantChange = geometry.size.width >= 270 && geometry.size.height >= 370
        if isNormalPuzzleWidth(.init(width: width, height: geometry.size.height)) || cantChange {
            return width
        } else {
            return width * (geometry.size.width >= 380 ? 0.8 : 0.87)
        }
    }
    
    var scaleResult:CGFloat {
        var scaleResult = scale * magnifyBy
        let minS = zoomMin
        if scaleResult <= minS {
            scaleResult = minS
        }
        if scaleResult >= zoomMax {
            scaleResult = zoomMax
        }
        return scaleResult
    }
    
    mutating func scalePlus() {
        scale += 0.5
    }
    
    mutating func scaleMinus() {
        scale -= 0.5
    }
    
    var zoomPercent:Int {
        let value = Int(scaleResult * 100)
        if isPuzzleType == .puzzle {
            return value - Int((minPuzzleScale - CGFloat(1)) * CGFloat(100))
        } else {
            return value
        }
    }
    
    var canZoomIn:Bool {
        !(scaleResult >= zoomMax)
    }
    
    var canZoomOut:Bool {
        scaleResult > 1
    }
    
    var isFullScreen:Bool = false
    
    func handleOffsetChange(offset:CGSize) -> CGSize {
        var newOffset: CGSize = .zero
        
        newOffset.width = offset.width + lastOffset.width
        newOffset.height = offset.height + lastOffset.height
        return newOffset
    }
}

extension CollectPuzzleViewModel {
    
    func isNavigationActive(for key:NavigationButtons) -> Bool {
        if key == .hint {
            return self.currentHint != nil
        }
        let defaultValue = key == .music ? true : false
        return navigationButtons[key] ?? defaultValue
    }
    
    mutating func setNavigationActive(for key:NavigationButtons, newValue:Bool) {
        if key == .hint && currentHint != nil {
            return
        }
        self.navigationButtons.updateValue(newValue, forKey: key)
        switch key {
        case .hint:
            if isCompleted {
                return
            }
            generateHint()
        case .music:
            [dropAudio, errorPuzzleAudio].forEach {
                $0?.canPlay = newValue
            }
            if newValue {
                backgroundAudio?.play()
            } else {
                backgroundAudio?.stop()
            }
        default:break
        }
    }
}

extension CollectPuzzleViewModel {
    mutating func dbUpdateCropped() {
        let updatedData = performUpdateCroppedDB()
        let newPuzzle = updatedData.puzzleItem
        var newPuzzles = updatedData.list
        let completedPeaces = newPuzzle?.completedPeaces ?? []
        if let currentHint,
           let first = completedPeaces.first(where: {$0.id == currentHint.id}),
           first.draggedID == currentHint.id {
            self.currentHint = nil
            hintEnabled = true
        }
        for i in 0..<newPuzzles.count {
            if newPuzzles[i].imageName == self.puzzleName {
                newPuzzles[i].hints = self.hints
            }
        }
        DB.db.puzzleList = newPuzzles
        if completedPeaces.isCompleted(),
           let newPuzzle {
            if !DB.db.isCompletionShowed(for: newPuzzle), !puzzleCompletionShowing {
                DB.db.puzzleCompleted(puzzle: newPuzzle)
                puzzleCompletionShowing = true
            }
        }
    }
    
    /// - Returns:
    /// - new PuzzleItem
    /// - new [PuzzleItem]
    private func performUpdateCroppedDB(newHints:Int? = nil) -> (
        puzzleItem: PuzzleItem?,
        list:[PuzzleItem]
    ) {
        var newCroppedItems:[CroppedPuzzleItem] = self.croppedImages
        newCroppedItems.removeImages()
        var dbPuzzles = DB.db.puzzleList
        var found = false
        var newItem:PuzzleItem?
        for i in 0..<dbPuzzles.count {
            if dbPuzzles[i].imageName == puzzleName {
                found = true
                dbPuzzles[i].completedPeaces = newCroppedItems
                newItem = dbPuzzles[i]
            }
        }
        if !found {
            dbPuzzles.append(.init(imageName: puzzleName, hints:newHints ?? self.hints, completedPeaces: newCroppedItems))
            newItem = dbPuzzles.last
        }
        return (puzzleItem: newItem,
                list: dbPuzzles)
    }
}

extension CollectPuzzleViewModel {
    enum NavigationButtons:String, CaseIterable {
        case music, crop, hint, preview
    }
}

extension CollectPuzzleViewModel.NavigationButtons {
    func image(isActive:Bool) -> ImageResource {
        return switch self {
        case .music:
            isActive ? .music : .soundOff
        case .crop:
            isActive ? .filterfill : .filterPuzzle
        case .hint:
                .hint
        case .preview:
            isActive ? .eye : .eyeClosed
        }
    }
}
