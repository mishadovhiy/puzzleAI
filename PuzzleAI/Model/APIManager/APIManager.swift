//
//  APIManager.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import UIKit

struct APIManager {
#warning("Token: OpenAI")
    static var openAIToken:String = "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"
    
    func generateImage(_ request:APIManager.Request.OpenAIRequest, completion: @escaping (_ image: UIImage?, _ error: MessageContent?) -> Void) {
        DispatchQueue(label: "api", qos: .userInitiated).async {
            self.generateImage(.openAiGenerate(request)) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let data):
                        completion(data.0, nil)
                    case .failure(let error):
#if DEBUG
                        print(error.localizedDescription, #file, #line)
#endif
                        completion(nil, .init(title: error.localizedDescription))
                    }
                }
            }
        }
    }
    
    private func generateImage(_ requestData:Request, completion: @escaping (Result<(UIImage, URL?), Error>) -> Void) {
        let urlString = requestData.url
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = requestData.method
        request.httpBody = requestData.body
        requestData.headers.forEach({
            request.setValue($0.value, forHTTPHeaderField: $0.key)
        })
        self.performRequest(request) { result in
            switch result {
            case .success(let success):
                let data = success
                if let openAI = self.unparce(data: data) {
                    self.loadImage(url: openAI.firstResponse?.url ?? "") { image in
                        completion(.success((image ?? .init(), .init(string: openAI.firstResponse?.url ?? ""))))
                    }
                } else if let image = UIImage(data: data) {
                    completion(.success((image, .init(string: ""))))
                } else {
                    completion(.failure(NSError(domain: "", code: -3)))
                }
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }
}

fileprivate extension APIManager {
    func performRequest(_ request:URLRequest, completion:@escaping(Result<Data, Error>)->Void){
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                let error = NSError(domain: "HTTP Error", code: statusCode, userInfo: nil)
                completion(.failure(error))
                return
            }
            
            if let data = data {
                completion(.success(data))
            } else {
                let error = NSError(domain: "Invalid image data", code: 0, userInfo: nil)
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    func unparce(data:Data) -> OpenAiGenerateResponse? {
        do {
            let response = try JSONDecoder().decode(OpenAiGenerateResponse.self, from: data)
            return response
        } catch let error {
#if DEBUG
            print("Decoding failed: \(error)")
#endif
            return nil
        }
    }
    
    func loadImage(url:String, completion:@escaping(_ image: UIImage?)->()) {
        if let url:URL = .init(string: url) {
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let data {
                    completion(.init(data: data))
                } else {
                    completion(nil)
                }
            }
            task.resume()
        } else {
            completion(nil)
        }
    }
}

extension APIManager {
    struct OpenAiGenerateResponse:Codable {
        var data:[DateResponse]
        var firstResponse:DateResponse? {
            return data.first
        }
        struct DateResponse:Codable {
            var url:String
        }
    }
}

