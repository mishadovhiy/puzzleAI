//
//  LoadingView.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import SwiftUI

struct LoadingView: View {
    var isLotille:Bool {
        return lotilleType != nil
    }
    var image:UIImage? = nil
    var lotilleType:LottieView.LottieType? = .primaryLoader
    var size:CGFloat = 120

    init(isLotille: LottieView.LottieType? = .primaryLoader, image:UIImage? = nil, size:CGFloat = 120, forceHideImage:Bool = false) {
        self.lotilleType = isLotille
        self.image = image
        let isLotille = isLotille != nil
        if isLotille && image == nil && !forceHideImage {
            self.image = .appIconSecondary
        }
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Color(.generalBackground)
                .frame(maxWidth:.infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all)
            VStack {
                if isLotille {
                    Spacer()
                }
                if let image {
                    Spacer()
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                }
                if isLotille {
                    Spacer()
                }
                VStack(content: {
                    ProgressView()
                        .tint((Color(uiColor: .init(named: "titleColor") ?? .red)))
                        .frame(width: 100, height: 100)
                        .environment(\.sizeCategory, .medium)
                })
                if isLotille {
                    Spacer()
                }
            }
            .scaledToFit()
            .aspectRatio(contentMode: .fit)
            .disabled(true)
        }
    }
}

#Preview {
    LoadingView()
}
