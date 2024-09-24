//
//  NoDataView.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import SwiftUI

struct NoDataView: View {
    var text:String?
    var imageResurce:ImageResource?
    var needImage = true
    var isLottile:LottieView.LottieType? = .noPuzzleList
    
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                if let isLottile {
                   // LoadingView(isLotille: isLottile, forceHideImage: true)
                    Image(.noList)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                    Spacer()
                        .frame(height: 50)
                } else {
                    if needImage {
                        Image(imageResurce ?? .no)
                            .foregroundColor(.descriptionText)
                    }
                }
                Text(text ?? "There's nothing here yet")
                    .setStyle(.description2)
                Spacer()
            }
            Spacer()
        }
    }
}

#Preview {
    NoDataView(text: nil)
}
