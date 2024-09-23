
import SwiftUI

extension GeneratePuzzleView {
    struct PuzzleGenerated {
        var resultImage:UIImage
    }
    
    struct GeneratePuzzleViewModel {
        var puzzleResponse:PuzzleGenerated? = nil
        var selectedItem:GeneratePuzzleViewModel.PhotoStyle? = .vivid
        var _prompt:String = ""
        var prompt:String {
            get {
                _prompt
            }
            set {
                if newValue.count <= 1000 {
                    _prompt = newValue
                }
            }
        }
        var promptValid:Bool {
            ![prompt.stringArray(from: .letters).count >= 3
            ].contains(where: {!$0})
        }
        var isLoading:Bool = false
        var error:MessageContent?

        private func startGenerateRequest(_ request:APIManager.Request.OpenAIRequest, _ completion:@escaping(_ image:UIImage?, _ error:MessageContent?)->()) {
            DispatchQueue(label: "api", qos: .utility).async {
                APIManager().generateImage(request) { result, error in
                    DispatchQueue.main.async {
                        completion(result, error)
                    }
                }
            }
        }
        
        func dismissKeyboard() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            
        }
        
        mutating func generateImage(request:APIManager.Request.OpenAIRequest, completion:@escaping(_ image:UIImage?, _ error:MessageContent?)->()) {
            dismissKeyboard()

            let selfValue = self
            if #available(iOS 17.0, *) {
                withAnimation(.linear(duration: 0.2)) {
                    self.isLoading = true
                } completion: {
                    selfValue.startGenerateRequest(request, completion)
                }
            } else {
                withAnimation(.linear(duration: 0.2)) {
                    self.isLoading = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200), execute: {
                    selfValue.startGenerateRequest(request, completion)
                })
            }
        }
        
        var isNextEnabled:Bool {
            return !prompt.isEmpty && promptValid && selectedItem != nil
        }
        
        mutating func generateRequestPressed(completion:@escaping( _ image:UIImage?, _ error:MessageContent?)->()) {
            if !isNextEnabled {
                return
            }
            generateImage(request: .init(prompt: prompt, selectedType: selectedItem?.toAPi ?? .natural)) { image, error in
                completion(image, error)
            }
        }
        
        func title(_ forValue:GeneratePuzzleViewText) -> String {
            forValue.rawValue
        }
        
        var nextImageTintColor:UIColor {
            .init(named: "titleColor") ?? .red
        }
    }
}

extension GeneratePuzzleView.GeneratePuzzleViewModel {
    enum GeneratePuzzleViewText: String {
        case navigationTitle = "Photo generation"
        case nextTitle = "Generate"
        case textEditorTitle = "Enter your Promt"
        case photoStyle = "Photo style"
        case promtExample = "Promt for example:"
        case promtExampleText = """
A dragon with feathers instead of scales and butterfly-like wings
"""
        case placeholder = """
Describe anything you want. Let our artificial intelligence work its magic for you...
"""
    }
    enum PhotoStyle: String, CaseIterable {
        case natural, vivid
        var toAPi:APIManager.Request.OpenAIRequest.Style {
            return switch self {
            case .natural:
                .natural
            case .vivid:
                    .vivid
            }
        }
        var content:MessageContent {
            return switch self {
            case .natural:
                    .init(title: "Natural", description: "Causes the model to produce more natural images", imageName: PhotoStyle.natural.rawValue)
            case .vivid:
                    .init(title: "Vivid", description: "Causes to lean towards generating hyper-real and dramatic images", imageName: PhotoStyle.vivid.rawValue)
            }
        }
    }
}
