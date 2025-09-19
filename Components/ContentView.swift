import SwiftUI
import FirebaseAuth
struct ContentView: View {
    @State private var showingSignIn = false
    @State private var currentUser: FirebaseAuth.User?
    @State private var authListener: AuthStateDidChangeListenerHandle?
    
    var body: some View {
        MainTabView() // <-- remove (currentUser: currentUser)
            .onAppear {
                currentUser = Auth.auth().currentUser
                
                // Show sign in sheet if not signed in
                if currentUser == nil {
                    showingSignIn = true
                }
                
                // Listen for auth state changes
                authListener = Auth.auth().addStateDidChangeListener { _, user in
                    withAnimation {
                        currentUser = user
                        if user == nil {
                            showingSignIn = true
                        }
                    }
                }
            }
            .onDisappear {
                if let listener = authListener {
                    Auth.auth().removeStateDidChangeListener(listener)
                    authListener = nil
                }
            }
            .fullScreenCover(isPresented: $showingSignIn) {
                SignInSheetView(showingSignIn: $showingSignIn)
            }
    }
}
#Preview {
    ContentView()
}
