
import SwiftUI

struct UserProgressView: View {
    
    @Binding var generateAIPresenting:Bool
    @State private var viewModel:UserProgressViewModel = .init()
    
    var body: some View {
        VStack {
            Spacer()
            VStack(alignment:.center) {
                Text("Your progress")
                    .setStyle(.bellowBigBlue)
                Spacer()
                    .frame(height: 12)
                VStack(spacing:6) {
                    Text(viewModel.collectPuzzleProgressText)
                        .setStyle(.biggest)
                    Text("Collected puzzles")
                        .setStyle(.description)
                }
                Spacer()
                    .frame(height: 24)
                ScrollView {
                    Image(.no)
                        .frame(height: 70)
                        .foregroundColor(.descriptionText2)
                    Spacer()
                        .frame(height: 8)
                    Text(viewModel.unlockText)
                        .setStyle()
                        .multilineTextAlignment(.center)
                }
                .frame(maxHeight: 175)
                Spacer()
                    .frame(height: 24)
                CointView(coint: .constant(.init(value: viewModel.unlockPrice)), labelText: "Price:")
                LoadingButton.configure(data: .init(title: "Open puzzle generation", pressed: {
                    viewModel.refillBalance() {
                        if !$0 {
                            self.generateAIPresenting = true
                        }
                    }
                }), nextEnabled: viewModel.isNextEnabled)
            }
            Spacer()
        }
        .padding(16)
        .background(.generalBackground)
    }
}
