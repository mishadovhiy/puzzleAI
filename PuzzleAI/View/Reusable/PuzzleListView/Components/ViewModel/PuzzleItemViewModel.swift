
import UIKit

extension PuzzleItemView {
    struct PuzzleItemViewModel {
        var deleteAlertPresenting:Bool = false
        func checkImage(_ newValue:String, isList:Bool, completion:@escaping(_ newImage:UIImage?) ->()) {
            if !newValue.contains("-") {
                completion(nil)
                return
            }
            DispatchQueue(label: "imageLoad", qos:.userInitiated).async {
                if newValue.contains("-") {
                    let fileManager = FileManagerModel()
                    fileManager.load(imageName: newValue, quality: isList ? .middle : .aboveMiddle) { newImage in
                        DispatchQueue.main.async {
                            completion(newImage)
                        }
                    }
                }
            }
        }
        
        var imageShadowColor:UIColor {
            (UIColor.init(named: "grey1") ?? .red).withAlphaComponent(0.1)
        }
        
        func deleteAiPressed(image:PuzzleItem, completion:@escaping() ->()) {
            if image.isCreatedByAI {
                let manager = FileManagerModel()
                manager.deleteItem(image) {
                    animate {
                        completion()
                    }
                }
            }
        }
        
        
        let alertConfirmDeletionText = "Are you sure you want to delete this puzzle? The data will be lost."
        func createAIContainerTitle(_ imageName:String) -> String {
            imageName == "" ? "AI create puzzle" : "Error loading image"
        }
    }
}
