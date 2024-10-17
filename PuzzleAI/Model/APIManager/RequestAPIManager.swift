//
//  APIManager.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import Foundation

extension APIManager {
    enum Request {
        case openAiGenerate(OpenAIRequest)
        
        var url:String {
            return switch self{
            case .openAiGenerate:"https://aimealplanner-ccc8d8d645ff.herokuapp.com/api/generateImage"
                //"https://api.openai.com/v1/images/generations"
            }
        }
        
        var headers: [String:String] {
            return switch self {
            case .openAiGenerate:
                [
                    "Content-Type":"application/json"
                ]
            }
        }
        
        var method:String {
            switch self {
            case .openAiGenerate:
                return "GET"
            }
        }
        
        var body:String? {
            switch self {
            case .openAiGenerate(let data):
                let userInput = data.prompt
                if userInput.count >= 1 {
                    let selectedName = data.selectedType
                    let escapedInput = userInput.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
                    
                    let requestData = """
              ?prompt=\(escapedInput)&style=\(selectedName)
              """.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
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
