//
//  SelectionScrollView.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import SwiftUI

struct SelectionScrollView: View {
    @State var data:[SelectionData]
    @Binding var selectedIndex:Int
    
    var body: some View {
        if #available(iOS 16.0, *) {
            ScrollView(.horizontal, showsIndicators: false) {
                scrollContent
            }
            .scrollIndicators(.hidden)
            .frame(height: 32 + 6)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                scrollContent
            }
            .frame(height: 32 + 6)
        }
    }
    
    var scrollContent:some View {
        HStack(spacing:12) {
            Spacer().frame(width: 4)
            ForEach((0..<data.count), id: \.self) { i in
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.descriptionText, lineWidth: 0.5)
                        .background(content: {
                            VStack {
                                self.selectedIndex == i ? Color.blueTint : Color.clear
                            }
                            .cornerRadius(18)
                        })
                    Button(action: {
                        withAnimation(.bouncy(duration: 0.3)) {
                            self.selectedIndex = i
                        }
                    }, label: {
                        Text(data[i].title)
                            .setStyle(i == selectedIndex ? .default : .description)
                            .padding(.leading, 12)
                            .padding(.trailing, 12)
                    })
                }
                .padding(.top, 3)
                .padding(.bottom, 3)
            }
            Spacer().frame(width: 4)
        }
        .padding(.leading, 0)
        .padding(.trailing, 0)
    }
}

extension SelectionScrollView {
    struct SelectionData {
        let title:String
    }
}
