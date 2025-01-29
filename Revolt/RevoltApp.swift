import SwiftUI
import Sentry
import Types


@main
struct RevoltApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    @Environment(\.locale) var systemLocale: Locale
    @StateObject var state = ViewState.shared ?? ViewState()

    init() {
        if !isPreview {
            SentrySDK.start { options in
                options.dsn = "https://4049414032e74d9098a44e67779aa648@sentry.revolt.chat/7"
                options.tracesSampleRate = 1.0
                options.profilesSampleRate = 1.0
                options.attachViewHierarchy = true
                options.enableAppLaunchProfiling = true
                //options.enableMetrics = true
            }
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
                                        state.currentSelection = .dms
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
                                                state.currentSelection = .server(server)
                                            } else {
                                                state.currentSelection = .dms
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
    @State var wasSignedOut = false
    @State var banner: WsState? = nil
    
    var body: some View {
        if viewState.state != .signedOut && !viewState.isOnboarding {
            InnerApp()
                .transition(.slide)
                .task {
                    await viewState.backgroundWsTask()
                    if viewState.state != .signedOut {
                        withAnimation {
                            viewState.state = .connecting
                        }
                    }
                }
                .alertPopup(show: banner !=  nil) {
                    if let banner = banner {
                        HStack {
                            switch banner {
                                case .disconnected:
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text("Disconnected")
                                        .bold()
                                    Text("Tap to reconnect")

                                case .connecting:
                                    Image(systemName: "arrow.clockwise")
                                    Text("Reconnecting")
                                case .connected:
                                    Image(systemName: "checkmark")
                                    Text("Connected")
                            }
                        }
                        .padding(8)
                        .foregroundStyle(.black)
                        .background {
                            let colour: Color

                            let _ = switch banner {
                                case .disconnected:
                                    colour = Color.red
                                case .connecting:
                                    colour = Color.yellow
                                case .connected:
                                    colour = Color.green
                            }
                            
                            RoundedRectangle(cornerRadius: 20).foregroundStyle(colour)
                        }
                        .onTapGesture {
                            if case .disconnected = banner {
                                viewState.ws?.forceConnect()
                            }
                        }
                    }
                }
                .onChange(of: colorScheme) { before, after in
                    // automatically switch the color scheme if the user pressed "auto" in the preferences menu
                    if viewState.theme.shouldFollowiOSTheme {
                        withAnimation {
                            _ = viewState.applySystemScheme(theme: after, followSystem: true)
                        }
                    }
                }
                .onChange(of: viewState.ws?.currentState, { before, after in
                    if case .connected = after {
                        banner = .connected
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                            withAnimation {
                                banner = nil
                            }
                        }
                    } else if before != nil {
                        banner = after
                    }
                })
        } else {
            Welcome(wasSignedOut: $wasSignedOut)
                .transition(.slideNext)
                .onAppear {
                    if viewState.state == .signedOut && viewState.sessionToken != nil { // signging out
                        viewState.sessionToken = nil
                        viewState.destroyCache()
                        withAnimation {
                            wasSignedOut = true
                        }
                    }
                }
        }
    }
}

struct InnerApp: View {
    @EnvironmentObject var viewState: ViewState

    var body: some View {
        NavigationStack(path: $viewState.path) {
            if viewState.forceMainScreen {
                MainApp()
            } else {
                switch viewState.state {
                    case .signedOut:
                        Text("Signed out... How did you get here?")
                    case .connecting:
                        VStack {
                            Text("Connecting...")
#if DEBUG
                            Button {
                                viewState.destroyCache()
                                viewState.sessionToken = nil
                                viewState.state = .signedOut
                            } label: {
                                Text("Developer: Nuke everything and force welcome screen")
                            }
#endif
                        }
                    case .connected:
                        MainApp()
                }
            }
        }
    }
}

struct MainApp: View {
    @EnvironmentObject var viewState: ViewState
    
    var body: some View {
        HomeRewritten(
            currentSelection: $viewState.currentSelection,
            currentChannel: $viewState.currentChannel
        )
        .navigationDestination(for: NavigationDestination.self) { dest in
            switch dest {
                case .channel_info(let id):
                    let channel = Binding($viewState.channels[id])!
                    ChannelInfo(channel: channel)
                case .channel_settings(let id):
                    let channel = Binding($viewState.channels[id])!
                    let server = channel.wrappedValue.server.map { $viewState.servers[$0] } ?? .constant(nil)
                    
                    ChannelSettings(server: server, channel: channel)
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
                case .create_server:
                    CreateServer()
                case .channel_search(let id):
                    let channel = Binding($viewState.channels[id])!
                    ChannelSearch(channel: channel)
                case .invite(let code):
                    ViewInvite(code: code)
                case .channel_pins(let id):
                    let channel = Binding($viewState.channels[id])!
                    ChannelPins(channel: channel)

            }
        }
        .environment(\.currentServer, viewState.currentSelection.id.flatMap { viewState.servers[$0] })
        .environment(\.currentChannel, viewState.currentChannel.id.flatMap { viewState.channels[$0] })
        .sheet(item: $viewState.currentUserSheet) { (v) in
            UserSheet(user: v.user, member: v.member)
        }
    }
}

// replace with settings eventually
let TEMP_IS_COMPACT_MODE: (Bool, Bool) = (false, true)

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

func copyUrl(url: URL) {
#if os(macOS)
    NSPasteboard.general.setString(url.absoluteString, forType: .URL)
#else
    UIPasteboard.general.url = url
#endif
}
