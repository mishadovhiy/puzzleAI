
import SwiftUI

struct SettingsTabView: View {
    
    @State var viewModel: SettingsViewModel = .init()
    @Binding var toHomePressed:Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing:8, content: {
                LoadingView(isLotille: nil)
                    .frame(height: viewModel.isLoading ? 30 : 0)
                    .opacity(viewModel.isLoading ? 1 : 0)
                
                itemView("Notification") {
                    viewModel.requestNotificationAccess(canOpenSettings:true, completion:{ _ in
                        
                    })
                }
                itemView("Rate Us", pressed: viewModel.rateAppPressed)
                itemView("Share App") {
                    viewModel.shareAppPressed()
                }
//                itemView("Privacy Policy") {viewModel.privacyPolicyPressed()}
//                itemView("Terms of Use") {viewModel.termsOfUsePressed()}
                itemView("Clear Data", distructive: true) {
                    self.viewModel.alertDeletePresenting = true
                }
                Spacer()
                    .frame(height: 2)
                Text("Version App " + viewModel.bundleVersion)
                    .setStyle(.description)
                    .padding(.bottom, 16)
            })
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .frame(alignment: .top)
            
        }
        .background(.generalBackground)
        .onAppear(perform: {
            viewModel.requestNotificationAccess(checkOnly: true, completion: { _ in
            })
        })
        .fullScreenCover(isPresented: .init(get: {
            viewModel.shareItem != nil
        }, set: {
            if !$0 {
                viewModel.shareItem = nil
            }
        })) {
            ActivityViewController(activityItems: [viewModel.shareItem!])
        }
        .alert("Clear Data", isPresented: $viewModel.alertDeletePresenting) {
            Button("Clear", role: .destructive) {
                self.viewModel.deleteDataPressed(completion: {
                    self.viewModel.isLoading = false
                    self.toHomePressed = true
                })
            }
            Button("Cancel", role: .cancel) {
                viewModel.alertDeletePresenting = false
            }
        } message: {
            Text(viewModel.confirmDeleteDataText)
        }
    }
    
    private func itemView(_ title:String, inactive:Bool = false, distructive:Bool = false, pressed:@escaping()->()) -> some View {
        Button {
            if inactive {
                return
            }
            pressed()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.container, style: .init(lineWidth: 0.5))
                HStack {
                    Text(title)
                        .foregroundColor(distructive ? .red : (Color(uiColor: .init(named: "titleColor") ?? .red)))
                        .setStyle(.defaultArticleBold)
                        .opacity(inactive ? 0.5 : 1)
                    Spacer()
                    Image(.arrowLeft)
                        .foregroundColor(.blueTint)
                }
                .frame(maxHeight: .infinity)
                .padding(.leading, 16)
                .padding(.trailing, 16)
            }
            .frame(height: 60)
        }
    }
}

