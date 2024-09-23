
import UIKit

struct FileManagerModel {
    private var icloudDirectoryURL: URL? {
        let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) ?? FileManager.default.temporaryDirectory
        
        let hiddenDirectoryURL = iCloudURL.appendingPathComponent("Documents").appendingPathComponent(".hiddenImages")
        do {
            try FileManager.default.createDirectory(at: hiddenDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
#if DEBUG
            print("Failed to create hidden iCloud directory: \(error)")
#endif
            return FileManager.default.temporaryDirectory
        }
        
        return hiddenDirectoryURL
    }
    
    /// Parameters:
    /// - startsAiFrom: all items, starting from the last, would have ai generation type, in PuzzleItem
    func saveImageList(_ stringList:[String], startsAiFrom aiNumber:Int, paidIndex:Int, completion:@escaping()->()) {
        let isAi = stringList.count <= aiNumber
        let isLocked = stringList.count <= paidIndex
        if let first = stringList.first
        {
            if let image = UIImage(named: first) {
                DispatchQueue(label: "db", qos: .userInitiated).async {
                    saveImage(image, aiType: isAi ? .demo : .none, isLocked: isLocked) { _ in
                        var new = stringList
                        new.removeFirst()
                        saveImageList(new, startsAiFrom: aiNumber, paidIndex: paidIndex, completion: completion)
                    }
                }
            } else {
                var new = stringList
                new.removeFirst()
                saveImageList(new, startsAiFrom: aiNumber, paidIndex: paidIndex, completion: completion)
            }
        } else {
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    func saveImage(_ image:UIImage, aiType:AIGenerationType, isLocked:Bool, completion:@escaping(Bool) -> Void) {
        let name = UUID().uuidString

        upload(ImageQuality.allCases, image, name: name) {
            DB.db.puzzleList.append(.init(imageName: name, paid:isLocked, aIGenerationType: aiType))
            completion(true)
        } error: {
            completion(false)
        }
        
    }
    
    func upload(_ qualities:[ImageQuality], _ original:UIImage, name:String, completion:@escaping()->(), error:@escaping()->()) {
        if let quality = qualities.first,
           let data = quality.data {
            upload(image: original.changeSize(newWidth: data.width), imageName: name + quality.rawValue, compressionQuality: quality.data?.compression ?? 1) {
                if $0 {
                    var new = qualities
                    new.removeFirst()
                    self.upload(new, original, name: name, completion: completion, error: error)
                } else {
                    error()
                }
            }
        } else {
            self.upload(image: original, imageName: name) {
                if $0 {
                    completion()
                } else {
                    error()
                }
            }
        }
    }
    
    private func upload(image: UIImage, imageName: String, compressionQuality: CGFloat = 1, completion: @escaping (Bool) -> Void) {
        guard let iCloudDirectoryURL = icloudDirectoryURL else {
            completion(false)
            return
        }
        
        let fileURL = iCloudDirectoryURL.appendingPathComponent(imageName).appendingPathExtension("png")
        
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            completion(false)
            return
        }
        
        do {
            try imageData.write(to: fileURL)
            completion(true)
        } catch {
#if DEBUG
            print("Failed to save image: \(error)")
#endif
            completion(false)
        }
    }
    
    func load(imageName: String, quality:ImageQuality, completion: @escaping (UIImage?) -> Void) {
        var imageName = imageName
        if quality != .original {
            imageName += quality.rawValue
        }
        guard let iCloudDirectoryURL = icloudDirectoryURL else {
            completion(nil)
            return
        }
        
        let fileURL = iCloudDirectoryURL.appendingPathComponent(imageName).appendingPathExtension("png")
        
        do {
            let imageData = try Data(contentsOf: fileURL)
            let originalImage = UIImage(data: imageData)
            DispatchQueue.main.async {
                guard let image = originalImage?.jpegData(compressionQuality: quality.data?.compression ?? 1) else {
                    completion(nil)
                    return
                }
                completion(UIImage(data:image))
            }
        } catch {
#if DEBUG
            print("Failed to load image: \(error)")
#endif
            completion(nil)
        }
    }
    
    
    /// deletes all images by names stored in local database
    /// doesn't remove all directory files
    func deleteDBAllImages(completion:@escaping()->()) {
        DispatchQueue(label: "db", qos: .userInitiated).async {
            let toDeleteList = DB.db.puzzleList.aiGeneratedList.filter({$0.aIGenerationType == .byUser})
            DB.db.puzzleList.removeAll(where: { listItem in
                toDeleteList.contains(where: {$0.imageName == listItem.imageName})
            })
            DB.db.puzzleList.clearGameProgress()
            self.deleteAllItems(items:toDeleteList.compactMap({$0.imageName})) {
                DB.clearDataBase {
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            }
        }
    }
    
    private func deleteAllItems(items:[String], completion:@escaping()->()) {
        let fileManager = FileManager.default
        guard let iCloudDirectoryURL = icloudDirectoryURL else {
            completion()
            return
        }
           do {
               let itemsDir = try fileManager.contentsOfDirectory(atPath: iCloudDirectoryURL.path)
               
               for item in itemsDir {
                   let itemPath = iCloudDirectoryURL.appendingPathComponent(item).path
                   if items.contains(where: {itemPath.contains($0)}) {
                       try fileManager.removeItem(atPath: itemPath)
                   }
               }
#if DEBUG
               print("All items in \(iCloudDirectoryURL.path) have been deleted.")
#endif
               completion()
           } catch {
#if DEBUG
               print("Failed to delete items in \(iCloudDirectoryURL.path): \(error)")
#endif
               completion()
           }
    }
    
    func deleteItem(_ name:PuzzleItem, completion:@escaping()->()) {
        DispatchQueue.init(label: "db", qos: .userInitiated).async {
            DB.db.puzzleList.removeAll {
                $0.imageName == name.imageName
            }
            self.delete(imageName: name.imageName) { _ in
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
    
    private func delete(imageName:String?, completion:@escaping(Bool)->()) {
        guard let imageName else {
            completion(false)
            return
        }
        ImageQuality.allCases.forEach { quality in
            let key = quality == .original ? "" : quality.rawValue
            self.performDelete(imageName: imageName + key) { _ in
                if quality == ImageQuality.allCases.last {
                    completion(true)
                }
            }
        }
    }
    
    private func performDelete(imageName:String?, completion:@escaping(Bool)->()) {
        guard let imageName, imageName != "" else {
            completion(false)
            return
        }
        guard let iCloudDirectoryURL = icloudDirectoryURL else {
            completion(false)
            return
        }
        
        let fileURL = iCloudDirectoryURL.appendingPathComponent(imageName).appendingPathExtension("png")
        do {
            try FileManager.default.removeItem(atPath: fileURL.path)
            completion(true)
        } catch {
#if DEBUG
            print(error, "error deleting image at: ", fileURL.absoluteString)
#endif
            completion(false)
        }
    }
}

enum ImageQuality: String, CaseIterable {
    case belowLowest
    case lowest
    case middle
    case aboveMiddle
    case original
    
    var data:QualityData? {
        return switch self {
        case .belowLowest:.init(width: 40, compression: 0.01)
        case .lowest:.init(width: 60, compression: 0.01)
        case .middle:.init(width: 115, compression: 0.1)
        case .aboveMiddle: .init(width: 180, compression: 0.1)
        case .original:nil
        }
    }
    struct QualityData {
        var width:CGFloat
        var compression:CGFloat
    }
}
