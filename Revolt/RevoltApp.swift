import SwiftUI

@main
struct RevoltApp: App {
    @StateObject var state = ViewState()
    
    var body: some Scene {
        WindowGroup {
            ApplicationSwitcher()
                .environmentObject(state)
        }
    }
}
    
struct ApplicationSwitcher: View {
    @EnvironmentObject var viewState: ViewState

    @ViewBuilder
    var body: some View {
        if viewState.sessionToken != nil {
            InnerApp()
                .task {
                    await viewState.backgroundWsTask()
                }
        } else {
            Login()
        }
    }
}

struct InnerApp: View {
    @EnvironmentObject var viewState: ViewState
    
    var body: some View {
        NavigationStack(path: $viewState.path) {
            switch viewState.state {
                case .connecting:
                    Text("Connecting...")
                case .connected:
                    Home()
            }
        }
    }
}
