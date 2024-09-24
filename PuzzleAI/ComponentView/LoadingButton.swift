//
//  LoadingButton.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import SwiftUI

struct LoadingButton: View {
    var data:ButtonData? = .init(title: "OK")
    @State private var isAnimating:Bool = false
    var nextEnabled:Bool = true
    var canAnimate:Bool = true
    @Binding var stopAnimation:Bool
    
    static func configure(data: ButtonData? = nil, nextEnabled: Bool = true, canAnimate: Bool = false) -> Self {
        return .init(data: data ?? .init(title: "OK"), nextEnabled: nextEnabled, canAnimate: canAnimate, stopAnimation: .constant(false))
    }
    
    var body:some View {
        let textType:Text.TextStyleType = data?.type == .primary ? .button : .secondaryButton
        let titleColor:UIColor = nextEnabled ? textType.color : (.init(named: "containerColor") ?? .red)
        return Button(action: {
            if !nextEnabled {
                return
            }
            if !canAnimate {
                data?.pressed?()
            } else {
                if isAnimatingGet {
                    return
                }
                animate {
                    isAnimating = true
                } completion: {
                    data?.pressed?()
                }
            }
        }, label: {
            VStack {
                if isAnimatingGet {
                    ProgressView()
                        .background(.blueTint)
                        .frame(width:30, height: 20)
                        .environment(\.sizeCategory, .medium)
                } else {
                    Text(data?.title ?? "OK")
                        .foregroundColor(.init(uiColor: titleColor))
                        .setStyle(textType)
                }
            }
        })
        .setStyle(nextEnabled, style:data?.type ?? .primary, maxWidth: isAnimatingGet ? 40 : .infinity)
        .onChange(of: stopAnimation) { newValue in
            if newValue {
                withAnimation {
                    isAnimating = false
                }
            }
        }
    }
    
    private var isAnimatingGet:Bool {
        isAnimating
    }
}
