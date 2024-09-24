//
//  Line.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import SwiftUI

struct Line: Shape {
    var y:CGFloat  = 0
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: y))
        path.addLine(to: CGPoint(x: rect.width, y: y))
        return path
    }
}

struct DefaultLine:View {
    @State var y: CGFloat = 0
    var body: some View {
        VStack {
            Line(y: y)
                .stroke(Color(uiColor: UIColor(named: "containerColor") ?? .red), lineWidth: 0.5)
                .frame(height:0.5)
        }
    }
}
