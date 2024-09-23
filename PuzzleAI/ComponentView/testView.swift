//
//  testView.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import SwiftUI

struct testView: View {
    let list:[String]
    init() {
    let list1 = Array(1..<70).compactMap({
            "test/\($0)"
        })
        let list2 = Array(1..<30).compactMap({
            "test/\($0)"
        })
        list = list1 + list2
        
    }
    var body: some View {
        ScrollView {
            ForEach(list, id: \.self) { string in
                LazyHGrid(rows: [
                    GridItem(.flexible(minimum: 50, maximum: 200), spacing: 8),
                    GridItem(.flexible(minimum: 50, maximum: 200), spacing: 8)
                ], content: {
                    Image(string)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                })
            }
        }
    }
}

#Preview {
    testView()
}
