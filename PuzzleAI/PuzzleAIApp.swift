//
//  PuzzleAIApp.swift
//  PuzzleAI
//
//  Created by Mykhailo Dovhyi on 19.09.2024.
//

import SwiftUI
import Combine

@main
struct PuzzleAIApp: App {
    static var adPresenting = PassthroughSubject<Bool, Never>()
    static func triggerAdPresenting(with newValue: Bool = false) {
        adPresenting.send(newValue)
    }
    static var bannerCompletedPresenting:(()->())?
    @State var adPresenting:Bool = false
    @State var adPresentingValue:Set<AnyCancellable> = []

    
    var body: some Scene {
        WindowGroup {
            HomeTabBarView()
                .onAppear(perform: {
                    PuzzleAIApp.adPresenting.sink { newValue in
                        self.adPresenting = newValue
                    }.store(in: &adPresentingValue)
                })
                .overlay {
                    if adPresenting {
                        AdPresenterRepresentable(dismissed: {
                            PuzzleAIApp.bannerCompletedPresenting?()
                            PuzzleAIApp.adPresenting.send(false)
                        })
                    } else {
                        VStack{
                            
                        }.disabled(true)
                    }
                }
        }
    }
}
