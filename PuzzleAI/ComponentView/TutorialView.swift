//
//  TutorialView.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 21.09.2024.
//

import SwiftUI

struct TutorialView: View {
    let title:String
    let position:CGPoint
    let okPressed:()->()
    var body: some View {
        ZStack {
            VStack(spacing:0) {
                HStack(alignment:.bottom) {
                    Image(.popoverArrow)
                        .scaledToFit()
                        .foregroundColor(.container)
                        //.position(x:screenSize.width - (geometry.size.width / 2), y:5)
                        .position(position)
                        .frame(height:8)
                }
                .frame(height: 8)
                RoundedRectangle(cornerRadius: 8)
                    .fill(.container)
            }
            
            VStack(spacing: 8) {
                Text(title)//viewModel.tutorialOverleyText)
                    .setStyle()
                    .minimumScaleFactor(0.2)
                
                HStack {
                    Spacer()
                    Button("Okey") {
                       // viewModel.dismissTutorialPressed()
                        okPressed()
                    }
                }
            }
            .padding(.top, 12 + 8)
            .padding(.bottom, 12)
            .padding(.leading, 12)
            .padding(.trailing, 12)
        }
      //  .frame(width: screenSize.width, height: 95)
      //  .position(.init(x: -8, y: geometry.size.height + 50))
        .zIndex(9999).opacity(1)
    }
}

