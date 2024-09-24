//
//  TextEditorView.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import SwiftUI

struct TextEditorView: View {
    @Binding var text:String
    var title:String?
    var placeholder:String?
    
    var body: some View {
        VStack(alignment:.leading) {
            if let title {
                Text(title)
                    .setStyle(.title)
            }
            ZStack {
                ZStack {
                    VStack {
                        Color(uiColor: .init(named: "containerColor")!)
                            .cornerRadius(16)
                    }
                    if text.isEmpty, let placeholder {
                        VStack(alignment:.leading) {
                            Text(placeholder)
                                .setStyle(.descriptionBold)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .frame(alignment: .leading)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)
                        .padding(.leading, 0)
                        .padding(.trailing, 16)
                    }
                }
                
                VStack(alignment:.trailing,spacing:0) {
                    textEditor
                    Text("\(text.count)/1000")
                        .setStyle(.descriptionSmall)
                }
                .padding(.top, 8)
                .padding(.leading, 0)
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
        }
        .onAppear(perform: {
#if os(iOS)
            UITextView.appearance().backgroundColor = .clear
#endif
        })
    }
    
    private var textEditor:some View {
        VStack {
            if #available(iOS 16.0, *) {
                performTextEditor
                    .scrollContentBackground(.hidden)
            } else {
                performTextEditor
            }
        }
    }
    
    private var performTextEditor: some View {
#if os(iOS)
        TextEditor(text: $text)
            .padding(.leading, 5)
            .background(.clear)
            .foregroundColor(.title)
            .font(Text.TextStyleType.default.font.font)
#else
        VStack {
            Text(text)
        }
#endif
    }
}
