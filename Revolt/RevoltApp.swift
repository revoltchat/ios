import SwiftUI

@main
struct RevoltApp: App {
    @StateObject var state = ViewState()
    
    var body: some Scene {
        WindowGroup {
            ApplicationSwitcher()
                .environmentObject(state)
                .tint(state.theme.accent.color)
                .background(state.theme.background.color)
                .foregroundStyle(state.theme.textColor.color)
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

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
