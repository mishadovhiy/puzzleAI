//
//  testView.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import SwiftUI

func animate(_ animationType:Animation = .bouncy, duration:Int? = nil,
             _ animate:@escaping()->(),
             completion:@escaping()->() = {}) {
#if os(iOS)
    if #available(iOS 17.0, *) {
        withAnimation(animationType) {
            animate()
        } completion: {
            completion()
        }
    } else {
        withAnimation(animationType) {
            animate()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(duration ?? 200), execute: {
            completion()
        })
    }
#else
    withAnimation {
        animate()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(duration ?? 200), execute: {
        completion()
    })
#endif
}

enum Keys:String {
    case appID = "6618149838"
    case storeKitCointKey
    case appGroup = "FQA2XH9ZUM.group.com.dovhiy.detectAppClose"
    case admob = "ca-app-pub-5463058852615321/8108848862"
}
