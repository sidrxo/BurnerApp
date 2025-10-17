import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        MainTabView()
            .fullScreenCover(isPresented: $appState.isSignInSheetPresented) {
                SignInSheetView(showingSignIn: $appState.isSignInSheetPresented)
            }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
