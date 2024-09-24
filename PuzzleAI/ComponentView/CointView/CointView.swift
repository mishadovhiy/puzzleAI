//
//  CointView.swift
//  PuzzlesAI
//
//  Created by Mykhailo Dovhyi on 17.09.2024.
//

import SwiftUI

struct CointView: View {
    @Binding var coint:Coint
    var labelText:String? = nil
    var isNavigationController:Bool = false
    @State var needOutline:Bool = false
    /// when true, the first two letters of the amount, would be displeyed
    var isValueCutted:Bool = false
    var contentView: some View {
        HStack(spacing:4) {
            Image(uiImage: .init(name: coint.type.imageName) ?? .coint)
            Text(textFieldText)
                .setStyle(.title)
        }
        .padding(.leading, 10)
        .padding(.trailing, isNavigationController ? -10 : 10)
    }
    
    var body: some View {
        HStack(spacing:4) {
            if let labelText {
                Text(labelText)
                    .setStyle(.descriptionBold)
            }
            if needOutline {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 50)
                        .stroke(.descriptionText, style: .init(lineWidth: 0.5))
                    contentView
                }
                .scaledToFit()
            } else {
                contentView
            }
        }
    }
    
    var textFieldText:String {
        if !isValueCutted {
            return coint.stringValue
        } else {
            if coint.value <= 999 {
                return coint.stringValue
            }
            var result:String = ""
            if coint.value >= 999 && coint.value <= 999999 {
                result = String(coint.stringValue.dropLast(3))
                result.append("K")
            } else if coint.value >= 1000000 {
                result = String(coint.stringValue.dropLast(6))
                result.append("M")
            }
            if result.count >= 3 {
                result.insert(".", at: result.index(result.startIndex, offsetBy: result.count - 2))
            }
            return result
        }
    }
}
