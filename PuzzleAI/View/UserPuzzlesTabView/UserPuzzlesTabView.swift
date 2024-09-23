
import SwiftUI

struct UserPuzzlesTabView: View {
    
    @Binding var generatePuzzlePressenting:Bool
    @Binding var user:User?
    @Binding var startOverPuzzle:PuzzleItem?
    @Binding var collectPuzzlePresenting:PuzzleItem?
    @Binding var puzzleModalPresenting:PuzzleItem?
    
    @State private var viewModel = UserPuzzlesTabViewModel()
    @Binding var showingTutorial:Bool

    var body: some View {
        GeometryReader { geometry in
            VStack {
                if !viewModel.isPaidAI {
                    UserProgressView(generateAIPresenting: $generatePuzzlePressenting)
                } else {
                PuzzleListView(viewModel: .init(.aiGenerated), generateAIPresenting: $generatePuzzlePressenting, startOverPressed: $startOverPuzzle, collectPuzzlePresenting: $collectPuzzlePresenting, puzzleModalPresenting: $puzzleModalPresenting, showingTutorial: $showingTutorial)
                }
            }
        }
    }
}
