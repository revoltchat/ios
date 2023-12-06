import SwiftUI

@main
struct RevoltApp: App {
    @Environment(\.locale) var systemLocale: Locale
    @StateObject var state = ViewState()
    
    var body: some Scene {
        WindowGroup {
            ApplicationSwitcher()
                .environmentObject(state)
                .tint(state.theme.accent.color)
                .background(state.theme.background.color)
                .foregroundStyle(state.theme.foreground.color)
                .typesettingLanguage((state.currentLocale ?? systemLocale).language)
                .onOpenURL { url in
                    if let first = url.pathComponents[safe: 1] {
                        switch first {
                            case "app", "login":
                                state.currentServer = .dms
                                state.currentChannel = .home
                            default:
                                ()
                        }
                    }
                }
        }
    }
}

struct ApplicationSwitcher: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewState: ViewState

    @ViewBuilder
    var body: some View {
        if viewState.sessionToken != nil && !viewState.isOnboarding {
            InnerApp()
                .task {
                    await viewState.backgroundWsTask()
                }
                .onChange(of: colorScheme) { before, after in
                    // automatically switch the color scheme if the user pressed "auto" in the preferences menu
                    if viewState.theme.shouldFollowiOSTheme {
                        withAnimation {
                            _ = viewState.applySystemScheme(theme: after, followSystem: true)
                        }
                    }
                }
        } else {
            Welcome()
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
                    HomeRewritten(
                        currentSelection: $viewState.currentServer,
                        currentChannel: $viewState.currentChannel,
                        currentServer: viewState.currentServer.id.flatMap { viewState.servers[$0] }
                    )
                    .navigationDestination(for: NavigationDestination.self) { dest in
                        switch dest {
                            case .channel_info(let id):
                                let channel =  Binding($viewState.channels[id])!
                                ChannelInfo(channel: channel)
                            case .channel_settings(let id):
                                let channel =  Binding($viewState.channels[id])!
                                ChannelInfo(channel: channel)  // TODO: channel settings
                            case .discover:
                                Discovery()
                            case .server_settings(let id):
                                let server = Binding($viewState.servers[id])!
                                ServerSettings(server: server)
                            case .settings:
                                Settings()
                        }
                    }
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

    @ViewBuilder
    func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
        if conditional {
            content(self)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func `if`<Content: View, Else: View>(_ conditional: Bool, content: (Self) -> Content, else other: (Self) -> Else) -> some View {
        if conditional {
            content(self)
        } else {
            other(self)
        }
    }
    
    @MainActor
    func applyPreviewModifiers(withState viewState: ViewState) -> some View {
        self.environmentObject(viewState)
            .tint(viewState.theme.accent.color)
            .foregroundStyle(viewState.theme.foreground.color)
            .background(viewState.theme.background.color)

    }
}

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}

#if targetEnvironment(macCatalyst)
let isIPad = UIDevice.current.userInterfaceIdiom == .pad
let isIPhone = UIDevice.current.userInterfaceIdiom == .phone
let isMac = true
#elseif os(iOS)
let isIPad = UIDevice.current.userInterfaceIdiom == .pad
let isIPhone = UIDevice.current.userInterfaceIdiom == .phone
let isMac = false
#else
let isIPad = false
let isIPhone = false
let isMac = true
#endif

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
