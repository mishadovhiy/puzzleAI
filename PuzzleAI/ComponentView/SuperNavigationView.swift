//
//  SuperNavigationView.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import SwiftUI

struct SuperNavigationView<Content: View>: View {
    let title:String
    var needBackButton:CloseType = .back
    var rightButtons:Content?
    var needPaddings:Bool = true
    var needSeparetor:Bool = true
    @Environment(\.dismiss) private var dismiss

    init(title: String, needBackButton:CloseType = .back, needPaddings:Bool = true, @ViewBuilder rightButtons: () -> Content, needSeparetor:Bool = true) {
        self.title = title
        self.needBackButton = needBackButton
        self.rightButtons = rightButtons()
        self.needPaddings = needPaddings
        self.needSeparetor = needSeparetor
    }
    
    var body: some View {
        VStack {
            HStack(spacing:1) {
                contentStack
                Spacer()
                HStack {
                    if let rightButtons {
                        rightButtons
                            .scaledToFit()
                    }
                }
            }
            .frame(height: 44)
            .padding(.leading, needPaddings ? 16 : 0)
            .padding(.trailing, needPaddings ? 16 : 0)
            if needSeparetor {
                Spacer()
                    .frame(height: 12)
                DefaultLine(y:8)
            }
        }
        .navigationBarHidden(true)
    }
    
    private var contentStack:some View {
        HStack(spacing:15) {
            HStack {
                if needBackButton != .none {
                    backButton
                }
            }
            Text(title)
                .setStyle(.navigationTitle)
                .lineLimit(1)
                .minimumScaleFactor(0.2)
        }
    }
    
    private var backButton: some View {
        Button(action: {
            dismiss()
        }, label: {
            ZStack {
                RoundedRectangle(cornerRadius: 50)
                    .stroke(.descriptionText, lineWidth: 0.5)
                if needBackButton == .closeIcon {
                    VStack {
                        Color(.descriptionText)
                            .cornerRadius(50)
                    }
                    .padding(8)
                }
                VStack {
                    Image(needBackButton == .closeIcon ? .close : .arrowLeft2)
                        .foregroundColor(needBackButton == .closeIcon ? .generalBackground : (Color(uiColor: .init(named: "titleColor") ?? .red)))
                        
                }
                .padding(2)
            }
        })
        .frame(width: 44, height: 44)
    }
}

extension SuperNavigationView {
    enum CloseType {
        case back
        case closeIcon
        case none
    }
}
