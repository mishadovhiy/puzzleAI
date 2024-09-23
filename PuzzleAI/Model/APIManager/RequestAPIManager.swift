
import Foundation

extension APIManager {
    enum Request {
        case openAiGenerate(OpenAIRequest)
        
        var url:String {
            return switch self{
            case .openAiGenerate:"https://api.openai.com/v1/images/generations"
            }
        }
        
        var headers: [String:String] {
            return switch self {
            case .openAiGenerate:
                [
                    "Content-Type":"application/json",
                    "Authorization":"Bearer \(openAIToken)",
                    "Accept": "/*",
                    "Accept-Encoding":"gzip, deflate, br"
                    
                ]
            }
        }
        
        var method:String {
            switch self {
            case .openAiGenerate:
                return "POST"
            }
        }
        
        var body:Data? {
            switch self {
            case .openAiGenerate(let data):
                let userInput = data.prompt
                if userInput.count >= 1 {
                    let selectedName = data.selectedType
                    let escapedInput = userInput.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
                    
                    let requestData = """
              {
                  "model": "dall-e-3",
                  "prompt": "\(escapedInput)",
                  "n": 1,
                  "size": "1024x1024",
                  "style":"\(selectedName)"
              }
              """.data(using: .utf8)
                    return requestData
                } else {
                    return nil
                }
            }
        }
    }
}

extension APIManager.Request {
    struct OpenAIRequest {
        var prompt:String
        enum Style:String {
            case vivid
            case natural
        }
        var selectedType:Style
    }
}
