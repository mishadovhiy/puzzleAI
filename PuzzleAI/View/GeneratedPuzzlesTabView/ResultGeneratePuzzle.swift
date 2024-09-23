
import SwiftUI

struct ResultGeneratePuzzle: View {
    var editorText:String
    var newImage:UIImage?
    @Binding var imageSaved:Bool
    @State var error:String? = nil
    @Environment(\.dismiss) private var dismiss
    @State var sharePressed:Bool = false
    var repeatPressed:(()->())?
    
    var body: some View {
        ZStack {
            VStack {
                SuperNavigationView(title: error == nil ? "Prompt result" : "", rightButtons: {
                    if let repeatPressed {
                        Button {
                            dismiss()
                            repeatPressed()
                        } label: {
                            Image(.repeat)
                                .foregroundColor(.blueTint)
                        }
                        
                    }
                })
                if error == nil && newImage != nil {
                    contentView
                } else {
                    errorView
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .background(.generalBackground)
        .popover(isPresented: $sharePressed) {
            ActivityViewController(activityItems: [newImage ?? .init()])
        }
    }
    
    func createPuzzlePressed() {
        guard let newImage else {
            self.error = "Error saving puzzle"
            return
        }
        Task {
            let manager = FileManagerModel()
            manager.saveImage(newImage, aiType: .byUser, isLocked: false) { ok in
                Task {
                    await MainActor.run {
                        if !ok {
                            self.error = "Error saving puzzle"
                        } else {
                            self.imageSaved = true
                            self.dismiss()
                        }
                    }
                }
            }
        }
    }
    
    func sharePuzzlePressed() {
        sharePressed = true
    }
    
    var contentView:some View {
        VStack {
            Image(uiImage: newImage!)
                .resizable()
                .frame(maxWidth: .infinity)
                .scaledToFit()
                .aspectRatio(contentMode: .fill)
                .cornerRadius(16)
            TextEditorView(text: .constant(editorText))
                .disabled(true)
            Spacer().frame(height: 29)
            VStack {
                LoadingButton(data: .init(title: "Create puzzle", pressed: createPuzzlePressed), stopAnimation: .constant(false))
                LoadingButton.configure(data: .init(title: "Share result", type: .secondary, pressed: sharePuzzlePressed))
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 16)
    }
    
    var errorView:some View {
        VStack {
            NoDataView(text: error)
            Spacer()
            Button {
                self.error = nil
                if newImage == nil {
                    dismiss()
                }
            } label: {
                Text("OK")
                    .setStyle(.button)
            }
            .primaryStyle
        }
        .padding(16)
    }
}

#Preview {
    ResultGeneratePuzzle.test
}

extension ResultGeneratePuzzle {
    static var test:ResultGeneratePuzzle {
        ResultGeneratePuzzle(editorText: "Tropical beach with white sand, palm trees and sunset on the horizon", newImage: .natural, imageSaved: .constant(false))
    }
}
