
import SwiftUI

extension Button {
    func setStyle(_ enabled:Bool, style:ButtonData.Style = .primary, maxWidth:CGFloat = .infinity) -> some View {
        ZStack {
            if style == .primary {
                primaryStyle(enabled, maxWidth: maxWidth)
            } else {
                secondaryStyle
            }
        }
    }
    func primaryStyle(_ enabled:Bool, maxWidth:CGFloat = .infinity) -> some View {
        return self
            .padding(.top, 14)
            .padding(.bottom, 14)
            .background(!enabled ? .gray : .blueTint)
            .cornerRadius(25)
            .frame(maxWidth: maxWidth)
            .frame(height: 50)
            .tint(Color(uiColor: .init(named: !enabled ? "containerColor" : "titleColor") ?? .red))
    }
    
    var primaryStyle: some View {
        self.primaryStyle(true)
    }
    
    var secondaryStyle: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .stroke(.blueTint, lineWidth: 1)
                .background(content: {
                    Color.clear
                })
            self
                .padding(.top, 14)
                .padding(.bottom, 14)
                .tint(.blueTint)
        }.frame(height: 50)
    }
    
    var closeStyle: some View {
        self
            .tint(.secondary)
            .frame(width: 30, height: 30)
            .background(.descriptionText)
            .cornerRadius(50)
    }
}
