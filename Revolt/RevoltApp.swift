import SwiftUI
import Sentry
import Types


@main
struct RevoltApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.locale) var systemLocale: Locale
    @StateObject var state = ViewState.shared ?? ViewState()

    init() {
        SentrySDK.start { options in
            options.dsn = "https://4049414032e74d9098a44e67779aa648@sentry.revolt.chat/7"
            options.tracesSampleRate = 1.0
            options.profilesSampleRate = 1.0
            options.enableTracing = true
            options.attachViewHierarchy = true
            options.enableAppLaunchProfiling = true
            options.enableMetrics = true
        }
    }

    var body: some Scene {
        WindowGroup {
            ApplicationSwitcher()
                .environmentObject(state)
                .tint(state.theme.accent.color)
                .background(state.theme.background.color)
                .foregroundStyle(state.theme.foreground.color)
                .typesettingLanguage((state.currentLocale ?? systemLocale).language)
                .onOpenURL { url in
                    print(url)
                    let components = NSURLComponents(string: url.absoluteString)
                    switch url.scheme {
                        case "http", "https":
                                switch url.pathComponents[safe: 1] {
                                    case "app", "login":
                                        state.currentServer = .dms
                                        state.currentChannel = .home
                                    default:
                                        ()
                                }
                        case "revoltchat":
                            var queryItems: [String: String] = [:]

                            for item in components?.queryItems ?? [] {
                                queryItems[item.name] = item.value?.removingPercentEncoding
                            }
                            switch url.host() {
                                case "users":
                                    if let id = queryItems["user"] {
                                        state.openUserSheet(withId: id, server: queryItems["server"])
                                    }
                                case "channels":
                                    if let id = queryItems["channel"] {
                                        if let channel = state.channels[id] {
                                            if let server = channel.server {
                                                state.currentServer = .server(server)
                                            } else {
                                                state.currentServer = .dms
                                            }

                                            state.currentChannel = .channel(id)
                                        }
                                    }
                                default:
                                    ()
                            }
                        default:
                            ()
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
                                ChannelSettings(channel: channel)
                            case .discover:
                                Discovery()
                            case .server_settings(let id):
                                let server = Binding($viewState.servers[id])!
                                ServerSettings(server: server)
                            case .settings:
                                Settings()
                            case .add_friend:
                                AddFriend()
                            case .create_group(let initial_users):
                                CreateGroup(selectedUsers: Set(initial_users.compactMap { viewState.users[$0] }))
                            case .add_server:
                                AddServer()
                        }
                    }
                    .sheet(item: $viewState.currentUserSheet) { (v) in
                        UserSheet(user: v.user, member: v.member)
                    }
            }
        }
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


var isPreview: Bool {
#if DEBUG
    ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
#else
    false
#endif
}

func copyText(text: String) {
#if os(macOS)
    NSPasteboard.general.setString(text, forType: .string)
#else
    UIPasteboard.general.string = text
#endif
    }
