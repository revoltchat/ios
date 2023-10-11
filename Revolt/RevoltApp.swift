import SwiftUI

@main
struct RevoltApp: App {
    @StateObject var state = ViewState()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ApplicationSwitcher()
            }
            .environmentObject(state)
        }
    }
}

struct ApplicationSwitcher: View {
    @EnvironmentObject var viewState: ViewState

    var body: some View {
        if (viewState.sessionToken != nil) {
            Home()
        } else {
            Login()
        }
    }
}
