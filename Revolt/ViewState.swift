import Foundation
import SwiftUI
import Alamofire
import ULID
import Collections
import Sentry
import Types
import UserNotifications
import KeychainAccess

enum UserStateError: Error {
    case signInError
    case signOutError
}

enum LoginState {
    case Success
    case Mfa(ticket: String, methods: [String])
    case Disabled
    case Invalid
    case Onboarding
}

struct LoginSuccess: Decodable {
    let result: String
    let _id: String
    let user_id: String
    let token: String
    let name: String
}

struct LoginMfa: Decodable {
    let result: String
    let ticket: String
    let allowed_methods: [String]
}

struct LoginDisabled: Decodable {
    let result: String
    let user_id: String
}

enum LoginResponse {
    case Success(LoginSuccess)
    case Mfa(LoginMfa)
    case Disabled(LoginDisabled)
}

extension LoginResponse: Decodable {
    enum CodingKeys: String, CodingKey { case result }
    enum Tag: String, Decodable { case Success, MFA, Disabled }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let singleValueContainer = try decoder.singleValueContainer()

        switch try container.decode(Tag.self, forKey: .result) {
            case .Success:
                self = .Success(try singleValueContainer.decode(LoginSuccess.self))
            case .MFA:
                self = .Mfa(try singleValueContainer.decode(LoginMfa.self))
            case .Disabled:
                self = .Disabled(try singleValueContainer.decode(LoginDisabled.self))
        }
    }
}

enum ConnectionState {
    case connecting, connected, signedOut
}

struct QueuedMessage {
    var nonce: String
    var replies: [ApiReply]
    var content: String
}

enum MainSelection: Hashable, Codable {
    case server(String)
    case dms

    var id: String? {
        switch self {
            case .server(let id):
                id
            case .dms:
                nil
        }
    }
}

enum ChannelSelection: Hashable, Codable {
    case channel(String)
    case home
    case friends
    case noChannel

    var id: String? {
        switch self {
            case .channel(let id): id
            default: nil
        }
    }
}

enum NavigationDestination: Hashable, Codable {
    case discover
    case settings
    case server_settings(String)
    case channel_info(String)
    case channel_settings(String)
    case add_friend
    case create_group([String])
    case create_server
    case channel_search(String)
    case invite(String)
}

struct UserMaybeMember: Identifiable {
    var user: Types.User
    var member: Member?
    
    var id: String { user.id }
}

@MainActor
public class ViewState: ObservableObject {
    static var shared: ViewState? = nil

#if os(iOS)
    static var application: UIApplication? = nil
#elseif os(macOS)
    static var application: NSApplication? = nil
#endif

    let keychain = Keychain(service: "chat.revolt.app")
    var http: HTTPClient = HTTPClient(token: nil, baseURL: "")
    var launchTransaction: any Sentry.Span
    
    @Published var ws: WebSocketStream? = nil
    
    @Published var apiInfo: ApiInfo? = nil {
        didSet {
            let apiInfo = apiInfo
            DispatchQueue.global(qos: .background).async {
                UserDefaults.standard.set(try! JSONEncoder().encode(apiInfo), forKey: "apiInfo")
                if let apiInfo = apiInfo {
                    self.http = HTTPClient(token: self.http.token, baseURL: apiInfo.app + "/api")
                }
            }
        }
    }

    @Published var sessionToken: String? = nil {
        didSet {
            keychain["sessionToken"] = sessionToken
        }
    }
    @Published var users: [String: Types.User] {
        didSet {
            let users = users
            DispatchQueue.global(qos: .background).async {
                UserDefaults.standard.set(try! JSONEncoder().encode(users), forKey: "users")
            }
        }
    }
    @Published var servers: OrderedDictionary<String, Server> {
        didSet {
            let servers = servers
            DispatchQueue.global(qos: .background).async {
                UserDefaults.standard.set(try! JSONEncoder().encode(servers), forKey: "servers")
            }
        }
    }
    @Published var channels: [String: Channel] {
        didSet {
            let channels = channels
            DispatchQueue.global(qos: .background).async {
                UserDefaults.standard.set(try! JSONEncoder().encode(channels), forKey: "channels")
            }
        }
    }
    @Published var messages: [String: Message] {
        didSet {
            let messages = messages
            DispatchQueue.global(qos: .background).async {
                UserDefaults.standard.set(try! JSONEncoder().encode(messages), forKey: "messages")
            }
        }
    }
    @Published var channelMessages: [String: [String]] {
        didSet {
            let channelMessages = channelMessages
            DispatchQueue.global(qos: .background).async {
                UserDefaults.standard.set(try! JSONEncoder().encode(channelMessages), forKey: "channelMessages")
            }
        }
    }
    @Published var members: [String: [String: Member]] {
        didSet {
            let members = members
            DispatchQueue.global(qos: .background).async {
                UserDefaults.standard.set(try! JSONEncoder().encode(members), forKey: "members")
            }
        }
    }
    @Published var dms: [Channel] {
        didSet {
            let dms = dms
            DispatchQueue.global(qos: .background).async {
                UserDefaults.standard.set(try! JSONEncoder().encode(dms), forKey: "dms")
            }
        }
    }
    @Published var emojis: [String: Emoji] {
        didSet {
            let emojis = emojis
            DispatchQueue.global(qos: .background).async {
                UserDefaults.standard.set(try! JSONEncoder().encode(emojis), forKey: "emojis")
            }
        }
    }
    
    @Published var currentUser: Types.User? = nil {
        didSet {
            let currentUser = currentUser
            DispatchQueue.global(qos: .background).async {
                UserDefaults.standard.set(try! JSONEncoder().encode(currentUser), forKey: "currentUser")
            }
        }
    }

    @Published var state: ConnectionState = .connecting
    @Published var forceMainScreen: Bool = false
    @Published var queuedMessages: [String: [QueuedMessage]] = [:]
    @Published var loadingMessages: Set<String> = Set()
    @Published var currentlyTyping: [String: OrderedSet<String>] = [:]
    @Published var isOnboarding: Bool = false
    @Published var unreads: [String: Unread] = [:]
    @Published var currentUserSheet: UserMaybeMember? = nil
    @Published var atTopOfChannel: Set<String> = []

    @Published var currentSelection: MainSelection {
        didSet {
            UserDefaults.standard.set(try! JSONEncoder().encode(currentSelection), forKey: "currentSelection")
        }
    }

    @Published var currentChannel: ChannelSelection {
        didSet {
            UserDefaults.standard.set(try! JSONEncoder().encode(currentChannel), forKey: "currentChannel")
        }
    }

    @Published var currentSessionId: String? = nil {
        didSet {
            UserDefaults.standard.set(currentSessionId, forKey: "currentSessionId")
        }
    }
    @Published var theme: Theme {
        didSet {
            UserDefaults.standard.set(try! JSONEncoder().encode(theme), forKey: "theme")
        }
    }
    
    @Published var currentLocale: Locale? {
        didSet {
            UserDefaults.standard.set(try! JSONEncoder().encode(currentLocale), forKey: "locale")
        }
    }

    @Published var path: NavigationPath {
        didSet {
            UserDefaults.standard.set(try! JSONEncoder().encode(path.codable), forKey: "path")
        }
    }
    
    var userSettingsStore: UserSettingsData

    static func decodeUserDefaults<T: Decodable>(forKey key: String, withDecoder decoder: JSONDecoder) throws -> T? {
        if let value = UserDefaults.standard.data(forKey: key) {
            return try decoder.decode(T.self, from: value)
        } else {
            return nil
        }
    }
    
    static func decodeUserDefaults<T: Decodable>(forKey key: String, withDecoder decoder: JSONDecoder, defaultingTo def: T) -> T {
        return (try? decodeUserDefaults(forKey: key, withDecoder: decoder)) ?? def
    }

    init() {
        launchTransaction = SentrySDK.startTransaction(name: "launch", operation: "launch")
        let decoder = JSONDecoder()
        
        // Load stored settings
        let settings = UserSettingsData.maybeRead(viewState: nil)
        
        // Only create HTTP client if we have a server URL
        if !settings.store.serverUrl.isEmpty {
            self.http = HTTPClient(token: nil, baseURL: "\(settings.store.serverUrl)")
        } else {
            self.http = HTTPClient(token: nil, baseURL: "")
        }
        
        self.apiInfo = ViewState.decodeUserDefaults(forKey: "apiInfo", withDecoder: decoder, defaultingTo: nil)
        
        self.userSettingsStore = UserSettingsData.maybeRead(viewState: nil)
        self.sessionToken = keychain["sessionToken"]

        self.users = ViewState.decodeUserDefaults(forKey: "users", withDecoder: decoder, defaultingTo: [:])
        self.servers = ViewState.decodeUserDefaults(forKey: "servers", withDecoder: decoder, defaultingTo: [:])
        self.channels = ViewState.decodeUserDefaults(forKey: "channels", withDecoder: decoder, defaultingTo: [:])
        self.messages = ViewState.decodeUserDefaults(forKey: "messages", withDecoder: decoder, defaultingTo: [:])
        self.channelMessages = ViewState.decodeUserDefaults(forKey: "channelMessages", withDecoder: decoder, defaultingTo: [:])
        self.members = ViewState.decodeUserDefaults(forKey: "members", withDecoder: decoder, defaultingTo: [:])
        self.dms = ViewState.decodeUserDefaults(forKey: "dms", withDecoder: decoder, defaultingTo: [])
        self.emojis = ViewState.decodeUserDefaults(forKey: "emojis", withDecoder: decoder, defaultingTo: [:])
        
        self.currentSelection = ViewState.decodeUserDefaults(forKey: "currentSelection", withDecoder: decoder, defaultingTo: .dms)
        self.currentChannel = ViewState.decodeUserDefaults(forKey: "currentChannel", withDecoder: decoder, defaultingTo: .home)
        self.currentLocale = ViewState.decodeUserDefaults(forKey: "locale", withDecoder: decoder, defaultingTo: nil)

        self.currentSessionId = UserDefaults.standard.string(forKey: "currentSessionId")

        self.theme = ViewState.decodeUserDefaults(forKey: "theme", withDecoder: decoder, defaultingTo: .dark)
        
        self.currentUser = ViewState.decodeUserDefaults(forKey: "currentUser", withDecoder: decoder, defaultingTo: nil)
        
        if let value = UserDefaults.standard.data(forKey: "path"), let path = try? decoder.decode(NavigationPath.CodableRepresentation.self, from: value) {
            self.path = NavigationPath(path)
        } else {
            self.path = NavigationPath()
        }
        
        if self.currentUser != nil, self.apiInfo != nil {
            self.forceMainScreen = true
        }

        self.users["00000000000000000000000000"] = User(id: "00000000000000000000000000", username: "Revolt", discriminator: "0000")
        self.http.token = self.sessionToken
        
        self.userSettingsStore.viewState = self // this is a cursed workaround
        ViewState.shared = self
    }

    func applySystemScheme(theme: ColorScheme, followSystem: Bool = false) -> Self {
        var theme: Theme = theme == .dark ? .dark : .light
        theme.shouldFollowiOSTheme = followSystem
        self.theme = theme
        return self
    }

    class func preview() -> ViewState {
        let this = ViewState()
        this.state = .connected
        this.currentUser = User(id: "0", username: "Zomatree", discriminator: "0000", badges: Int.max, status: Status(text: "hello world", presence: .Busy), relationship: .User, profile: Profile(content: "hello world"))
        this.users["0"] = this.currentUser!
        this.users["1"] = User(id: "1", username: "Other Person", discriminator: "0001", profile: Profile(content: "Balls"))
        this.servers["0"] = Server(id: "0", owner: "0", name: "Testing Server", channels: ["0"], default_permissions: Permissions.all, categories: [Types.Category(id: "0", title: "Channels", channels: ["0", "1"])])
        this.channels["0"] = .text_channel(TextChannel(id: "0", server: "0", name: "General"))
        this.channels["1"] = .voice_channel(VoiceChannel(id: "1", server: "0", name: "Voice General"))
        this.channels["2"] = .saved_messages(SavedMessages(id: "2", user: "0"))
        this.channels["3"] = .dm_channel(DMChannel(id: "3", active: true, recipients: ["0", "1"]))
        this.messages["01HD4VQY398JNRJY60JDY2QHA5"] = Message(id: "01HD4VQY398JNRJY60JDY2QHA5", content: String(repeating: "HelloWorld", count: 100), author: "0", channel: "0", mentions: ["0"])
        this.messages["01HDEX6M2E3SHY8AC2S6B9SEAW"] = Message(id: "01HDEX6M2E3SHY8AC2S6B9SEAW", content: "reply", author: "0", channel: "0", replies: ["01HD4VQY398JNRJY60JDY2QHA5"])
        this.messages["01HZ3CFEG10WH52YVXG34WZ9EM"] = Message(id: "01HZ3CFEG10WH52YVXG34WZ9EM", content: "Followup", author: "0", channel: "0")
        this.channelMessages["0"] = ["01HD4VQY398JNRJY60JDY2QHA5", "01HDEX6M2E3SHY8AC2S6B9SEAW", "01HZ3CFEG10WH52YVXG34WZ9EM"]
        this.members["0"] = ["0": Member(id: MemberId(server: "0", user: "0"), joined_at: "")]
        this.emojis = ["0": Emoji(id: "01GX773A8JPQ0VP64NWGEBMQ1E", parent: .server(EmojiParentServer(id: "0")), creator_id: "0", name: "balls")]
        this.currentSelection = .server("0")
        this.currentChannel = .channel("0")
        this.dms.append(contentsOf: [this.channels["2"]!, this.channels["3"]!])

        for i in (1...9) {
            this.users["\(i)"] = User(id: "\(i)", username: "\(i)", discriminator: "\(i)\(i)\(i)\(i)", relationship: .Friend)
        }

        this.currentlyTyping["0"] = ["0", "1", "2", "3", "4"]

        this.apiInfo = ApiInfo(revolt: "0.6.6", features: ApiFeatures(captcha: CaptchaFeature(enabled: true, key: "3daae85e-09ab-4ff6-9f24-e8f4f335e433"), email: true, invite_only: false, autumn: RevoltFeature(enabled: true, url: "https://autumn.revolt.chat"), january: RevoltFeature(enabled: true, url: "https://jan.revolt.chat"), voso: VortexFeature(enabled: true, url: "https://vortex.revolt.chat", ws: "wss://vortex.revolt.chat")), ws: "wss://ws.revolt.chat", app: "https://app.revolt.chat", vapid: "BJto1I_OZi8hOkMfQNQJfod2osWBqcOO7eEOqFMvCfqNhqgxqOr7URnxYKTR4N6sR3sTPywfHpEsPXhrU9zfZgg=")

        return this
    }

    func signInWithVerify(code: String, email: String, password: String) async -> Bool {
        guard let baseUrl = apiInfo?.app else {
            return false
        }
        
        // Update HTTP client with current server URL
        self.http = HTTPClient(token: nil, baseURL: baseUrl)
        
        do {
            _ = try await self.http.createAccount_VerificationCode(code: code).get()
        } catch {
            return false
        }
        
        await signIn(email: email, password: password, callback: {a in print(String(describing: a))})
        // awful workaround for the verification endpoint returning invalid session tokens
        return true
    }

    func signIn(mfa_ticket: String, mfa_response: [String: String], callback: @escaping((LoginState) -> ())) async {
        let body = ["mfa_ticket": mfa_ticket, "mfa_response": mfa_response, "friendly_name": "Revolt iOS"] as [String : Any]

        await innerSignIn(body, callback)
    }

    func signIn(email: String, password: String, callback: @escaping((LoginState) -> ())) async {
        // First fetch API info
        let baseUrl = apiInfo?.app
        
        do {
            let fetchedApiInfo = try await http.fetchApiInfo().get()
            self.apiInfo = fetchedApiInfo
            self.http.apiInfo = fetchedApiInfo
            self.http = HTTPClient(token: nil, baseURL: fetchedApiInfo.app + "/api")
            
            // Now proceed with login
            let body = ["email": email, "password": password, "friendly_name": "Revolt IOS"]
            await innerSignIn(body, callback)
        } catch {
            callback(.Invalid)
            return
        }
    }

    private func innerSignIn(_ body: [String: Any], _ callback: @escaping((LoginState) -> ())) async {
        guard let baseUrl = apiInfo?.app else {
            return callback(.Invalid)
        }
        
        let loginUrl = "\(baseUrl)/api/auth/session/login"
        AF.request(loginUrl, method: .post, parameters: body, encoding: JSONEncoding.default)
            .responseData { response in

                switch response.result {
                    case .success(let data):
                        if [401, 500].contains(response.response!.statusCode) {
                            return callback(.Invalid)
                        }
                        let result = try! JSONDecoder().decode(LoginResponse.self, from: data)
                        switch result {
                            case .Success(let success):
                                Task {
                                    self.isOnboarding = true
                                    self.currentSessionId = success._id
                                    self.sessionToken = success.token
                                    self.http.token = success.token
                                    
                                    await self.promptForNotifications()
                                    
                                    do {
                                        let onboardingState = try await self.http.checkOnboarding().get()
                                        if onboardingState.onboarding {
                                            callback(.Onboarding)
                                        } else {
                                            self.isOnboarding = false
                                            callback(.Success)
                                            self.state = .connecting
                                        }
                                    } catch {
                                        self.isOnboarding = false
                                        self.state = .connecting
                                        return callback(.Success) // if the onboard check dies, just try to go for it
                                    }
                                }

                            case .Mfa(let mfa):
                                return callback(.Mfa(ticket: mfa.ticket, methods: mfa.allowed_methods))

                            case .Disabled:
                                return callback(.Disabled)
                        }
                    case .failure(_):
                        ()
                }
            }
    }

    /// A successful result here means pending (the session has been destroyed but the client still has data cached)
    func signOut() async -> Result<(), UserStateError>  {
        let status = try? await http.signout().get()
        guard let status = status else { return .failure(.signOutError)}
        self.ws?.stop()
        
        withAnimation {
            state = .signedOut
            userSettingsStore.store.serverUrl = ""  // Clear server URL on sign out
        }
        
        // IMPORTANT: do not destroy the cache/session here. It'll cause the app to crash before it can transition to the welcome screen.
        // The cache is destroyed in RevoltApp.swift:ApplicationSwitcher
        
        return .success(())
    }
    
    /// A workaround for the UserSettingStore finding out we're not authenticated, since not a main actor.
    func setSignedOutState() {
        withAnimation {
            state = .signedOut
            userSettingsStore.store.serverUrl = ""  // Clear server URL on sign out
        }
    }
    
    func destroyCache() {
        // In future this'll need to delete files too
        path = NavigationPath()

        users.removeAll()
        servers.removeAll()
        channels.removeAll()
        messages.removeAll()
        members.removeAll()
        emojis.removeAll()
        dms.removeAll()
        currentlyTyping.removeAll()
        channelMessages.removeAll()
        
        currentUser = nil
        currentSelection = .dms
        currentChannel = .home
        currentSessionId = nil
        
        userSettingsStore.isLoggingOut()
        self.ws = nil
    }
    
    func promptForNotifications() async {
        let notificationsGranted = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound, .providesAppNotificationSettings])
        if notificationsGranted != nil && notificationsGranted! {
            ViewState.application?.registerForRemoteNotifications()
            self.userSettingsStore.store.notifications.rejectedRemoteNotifications = false
        } else {
            self.userSettingsStore.store.notifications.rejectedRemoteNotifications = true
        }
        self.userSettingsStore.writeStoreToFile()
    }

    func formatUrl(with: File) -> String {
        "\(apiInfo!.features.autumn.url)/\(with.tag)/\(with.id)"
    }
    
    func formatUrl(fromEmoji emojiId: String) -> String {
        "\(apiInfo!.features.autumn.url)/emojis/\(emojiId)"
    }
    
    func formatUrl(fromId id: String, withTag tag: String) -> String {
        "\(apiInfo!.features.autumn.url)/\(tag)/\(id)"
    }
    
    func backgroundWsTask() async {
        if ws != nil {
            return
        }

        guard let token = sessionToken else {
            state = .signedOut
            return
        }

        let fetchApiInfoSpan = launchTransaction.startChild(operation: "fetchApiInfo")
        
        do {
            let apiInfo = try await self.http.fetchApiInfo().get()
            self.http.apiInfo = apiInfo
            self.apiInfo = apiInfo
        } catch {
            SentrySDK.capture(error: error)
            state = .connecting
            fetchApiInfoSpan.finish()
            return
        }
        
        fetchApiInfoSpan.finish()

        let ws = WebSocketStream(url: apiInfo!.ws, token: token, onEvent: onEvent)
        self.ws = ws
    }

    func queueMessage(channel: String, replies: [Reply], content: String, attachments: [(Data, String)]) async {
        var queue = self.queuedMessages[channel]

        if queue == nil {
            queue = []
            self.queuedMessages[channel] = queue
        }

        let nonce = ULID(timestamp: Date.now).ulidString

        var r: [ApiReply] = []

        for reply in replies {
            r.append(ApiReply(id: reply.message.id, mention: reply.mention))
        }

        queue!.append(QueuedMessage(nonce: nonce, replies: r, content: content))

        await http.sendMessage(channel: channel, replies: r, content: content, attachments: attachments, nonce: nonce)
    }

    func onEvent(_ event: WsMessage) async {
        switch event {
            case .ready(let event):
                let processReadySpan = launchTransaction.startChild(operation: "processReady")
                
                for channel in event.channels {
                    channels[channel.id] = channel
                    
                    if channelMessages[channel.id] == nil {
                        channelMessages[channel.id] = []
                    }
                }

                for server in event.servers {
                    servers[server.id] = server
                    
                    if members[server.id] == nil {
                        members[server.id] = [:]
                    }
                }

                for user in event.users {
                    if user.relationship == .User {
                        currentUser = user
                    }

                    users[user.id] = user
                }
                
                for member in event.members {
                    members[member.id.server]![member.id.user] = member
                }

                dms = try! await http.fetchDms().get()

                for dm in dms {
                    if channelMessages[dm.id] == nil {
                        channelMessages[dm.id] = []
                    }
                }

                let unreads = try! await http.fetchUnreads().get()

                for unread in unreads {
                    self.unreads[unread.id.channel] = unread
                }
                
                for emoji in event.emojis {
                    self.emojis[emoji.id] = emoji
                }

                state = .connected
                ws?.currentState = .connected
                ws?.retryCount = 0
                await verifyStateIntegrity()
                
                processReadySpan.finish()
                launchTransaction.finish()
                
                for channel in channels.values {
                    if let last_message_id = channel.last_message_id,
                       let last_cached_message = channelMessages[channel.id]?.last,
                       last_message_id != last_cached_message
                    {
                        if last_message_id != last_cached_message {
                            // TODO: load newer messages - blocked on rewriting loading messages up and down the channel
                            channelMessages[channel.id] = []
                        }
                    }
                }

            case .message(let m):
                if let user = m.user {
                    users[user.id] = user
                }
                
                if let member = m.member {
                    members[member.id.server]?[member.id.user] = member
                }

                messages[m.id] = m
                unreads[m.channel]?.last_id = channelMessages[m.channel]?.last
                channelMessages[m.channel]?.append(m.id)

            case .message_update(let event):
                let message = messages[event.id]

                if var message = message {
                    message.edited = event.data.edited

                    if let content = event.data.content {
                        message.content = content
                    }

                    messages[event.id] = message
                }

            case .authenticated:
                print("authenticated")

            case .invalid_session:
                Task {
                    await self.signOut()
                }

            case .channel_start_typing(let e):
                var typing = currentlyTyping[e.id] ?? []
                typing.append(e.user)

                currentlyTyping[e.id] = typing

            case .channel_stop_typing(let e):
                currentlyTyping[e.id]?.removeAll(where: { $0 == e.user })

            case .message_delete(let e):
                if var channel = channelMessages[e.channel] {
                    if let index = channel.firstIndex(of: e.id) {
                        channel.remove(at: index)
                        channelMessages[e.channel] = channel
                    }
                }

            case .channel_ack(let e):
                unreads[e.id]?.last_id = e.message_id
                unreads[e.id]?.mentions?.removeAll { $0 <= e.message_id }
            
            case .message_react(let e):
                if var message = messages[e.id] {
                    var reactions = message.reactions ?? [:]
                    var users = reactions[e.emoji_id] ?? []
                    users.append(e.user_id)
                    reactions[e.emoji_id] = users
                    message.reactions = reactions
                    messages[e.id] = message
                }
            
            case .message_unreact(let e):
                if var message = messages[e.id] {
                    if var reactions = message.reactions {
                        if var users = reactions[e.emoji_id] {
                            users.removeAll { $0 == e.user_id }
                            
                            if users.isEmpty {
                                reactions.removeValue(forKey: e.emoji_id)
                            } else {
                                reactions[e.emoji_id] = users
                            }
                            message.reactions = reactions
                            messages[e.id] = message
                        }
                    }
                }
            case .message_append(let e):
                if var message = messages[e.id] {
                    var embeds = message.embeds ?? []
                    embeds.append(e.append)
                    message.embeds = embeds
                    messages[e.id] = message
                }
        }
    }

    func joinServer(code: String) async -> JoinResponse {
        let response = try! await http.joinServer(code: code).get()

        for channel in response.channels {
            channels[channel.id] = channel
            channelMessages[channel.id] = []
        }

        servers[response.server.id] = response.server

        return response
    }

    func openDm(with user: String) async {
        var channel = dms.first(where: { switch $0 {
            case .dm_channel(let dm):
                return dm.recipients.contains(user)
            case _:
                return false
        } })

        if channel == nil {
            channel = try! await http.openDm(user: user).get()
            dms.append(channel!)
        }

        currentSelection = .dms
        currentChannel = .channel(channel!.id)
    }

    func getUnreadCountFor(channel: Channel) -> UnreadCount? {
        if let unread = unreads[channel.id] {
            if let mentions = unread.mentions {
                return .mentions(mentions.count)
            }

            if let last_unread_id = unread.last_id, let last_message_id = channel.last_message_id {
                if last_unread_id < last_message_id {
                    return .unread
                }
            }
        }

        return nil
    }

    func getUnreadCountFor(server: Server) -> UnreadCount? {
        if let serverNotificationValue = userSettingsStore.cache.notificationSettings.server[server.id] {
            if serverNotificationValue == .muted && serverNotificationValue == .none {
                return nil
            }
        }
        
        let channelUnreads = server.channels
            .compactMap { channels[$0] }
            .map { ($0, getUnreadCountFor(channel: $0)) }

        var mentionCount = 0
        var hasUnread = false

        for (channel, unread) in channelUnreads {
            let channelNotificationValue = userSettingsStore.cache.notificationSettings.channel[channel.id]
            
            if let unread = unread {
                switch unread {
                    case .unread:
                        if channelNotificationValue != NotificationState.none && channelNotificationValue != .muted {
                            hasUnread = true
                        }
                        
                    case .mentions(let count):
                        if channelNotificationValue != NotificationState.none && channelNotificationValue != .mention {
                            mentionCount += count
                        }
                }
            }
        }

        if mentionCount > 0 {
            return .mentions(mentionCount)
        } else if hasUnread {
            return .unread
        }

        return nil
    }
    
    func openUserSheet(withId id: String, server: String?) {
        if let user = users[id] {
            let member = server
                .flatMap { members[$0] }
                .flatMap { $0[id] }
            
            currentUserSheet = UserMaybeMember(user: user, member: member)
        }
    }
    
    func openUserSheet(user: Types.User, member: Member? = nil) {
        currentUserSheet = UserMaybeMember(user: user, member: member)
    }
    
    public var openServer: Server? {
        if case .server(let serverId) = currentSelection {
            return servers[serverId]
        }
        
        return nil
    }
    
    public var openServerMember: Member? {
        if case .server(let serverId) = currentSelection, let userId = currentUser?.id {
            return members[serverId]?[userId]
        }
        
        return nil
    }
    
    func verifyStateIntegrity() async {
        if currentUser == nil {
            logger.warning("Current user is empty, logging out")
            try! await signOut().get()
        }
        
        if let token = UserDefaults.standard.string(forKey: "sessionToken") {
            UserDefaults.standard.removeObject(forKey: "sessionToken")
            keychain["sessionToken"] = token
        }
        
        if case .channel(let id) = currentChannel {
            if let channel = channels[id] {
                if let serverId = channel.server, currentSelection == .dms {
                    logger.warning("Current channel is a server channel but selection is dms")
                    
                    currentSelection = .server(serverId)
                }
            } else {
                logger.warning("Current channel no longer exists")
                currentSelection = .dms
                currentChannel = .home
            }
        }
        
        if case .server(let id) = currentSelection {
            if servers[id] == nil {
                logger.warning("Current server no longer exists")
                currentSelection = .dms
                currentChannel = .home
            }
        }
    }
    
    func selectServer(withId id: String) {
        currentSelection = .server(id)
        
        if let last = userSettingsStore.store.lastOpenChannels[id] {
            currentChannel = .channel(last)
        } else if let server = servers[id] {
            if let firstChannel = server.channels.compactMap({
                switch channels[$0] {
                    case .text_channel(let c):
                        return c
                    default:
                        return nil
                }
            }).first {
                currentChannel = .channel(firstChannel.id)
            } else {
                currentChannel = .noChannel
            }
        }
    }
    
    func selectChannel(inServer server: String, withId id: String) {
        currentChannel = .channel(id)
        userSettingsStore.store.lastOpenChannels[server] = id
    }
    
    func selectDms() {
        currentSelection = .dms
        
        if let last = userSettingsStore.store.lastOpenChannels["dms"] {
            currentChannel = .channel(last)
        } else {
            currentChannel = .home
        }
    }
    
    func selectDm(withId id: String) {
        currentChannel = .channel(id)
        let channel = channels[id]!
        
        switch channel {
            case .dm_channel, .group_dm_channel:
                userSettingsStore.store.lastOpenChannels["dms"] = id
            default:
                userSettingsStore.store.lastOpenChannels.removeValue(forKey: "dms")
                
        }
    }
    
    func resolveAvatarUrl(user: Types.User, member: Member?, masquerade: Masquerade?) -> URL {
        if let avatar = masquerade?.avatar, let url = URL(string: avatar) {
            return url
        }
        
        if let avatar = member?.avatar, let url = URL(string: formatUrl(with: avatar)) {
            return url
        }
        
        if let avatar = user.avatar, let url = URL(string: formatUrl(with: avatar)) {
            return url
        }
        
        return URL(string: "\(http.baseURL)/users/\(user.id)/default_avatar")!
    }
}

enum UnreadCount {
    case unread
    case mentions(Int)
}

extension Dictionary {
    mutating func setDefault(key: Key, default def: Value) -> Value {
        var value = self[key]

        if value == nil {
            value = def
            self[key] = value
        }

        return value!
    }
}

extension Channel {
    @MainActor
    public func getName(_ viewState: ViewState) -> String {
        switch self {
            case .saved_messages(_):
                "Saved Messages"
            case .dm_channel(let c):
                viewState.users[c.recipients.first(where: {$0 != viewState.currentUser!.id})!]!.username
            case .group_dm_channel(let c):
                c.name
            case .text_channel(let c):
                c.name
            case .voice_channel(let c):
                c.name
        }
    }
}
