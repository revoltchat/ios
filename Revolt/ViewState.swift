import Foundation
import SwiftUI
import Alamofire
import ULID
import Collections

enum UserStateError: Error {
    case signInError
    case signOutError
}

enum LoginState {
    case Success
    case Mfa(ticket: String, methods: [String])
    case Disabled
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
    case connecting
    case connected
}

struct QueuedMessage {
    var nonce: String
    var replies: [ApiReply]
    var content: String
}

@MainActor
public class ViewState: ObservableObject {
    var http: HTTPClient = HTTPClient(token: nil, baseURL: "https://api.revolt.chat")
    var ws: WebSocketStream? = nil
    var apiInfo: ApiInfo? = nil

    @Published var sessionToken: String? = nil {
        didSet {
            UserDefaults.standard.set(sessionToken, forKey: "sessionToken")
        }
    }
    @Published var users: [String: User] = [:]
    @Published var servers: OrderedDictionary<String, Server> = [:]
    @Published var channels: [String: Channel] = [:]
    @Published var messages: [String: Message] = [:]
    @Published var channelMessages: [String: [String]] = [:]
    @Published var members: [String: [String: Member]] = [:]
    @Published var dms: [Channel] = []
    
    @Published var state: ConnectionState = .connecting
    @Published var queuedMessages: Dictionary<String, [QueuedMessage]> = [:]
    @Published var currentUser: User? = nil
    @Published var loadingMessages: Set<String> = Set()
    @Published var currentlyTyping: [String: [String]] = [:]

    @Published var currentServer: String? = nil {
        didSet {
            UserDefaults.standard.set(currentServer, forKey: "currentServer")
        }
    }

    @Published var currentChannel: String? = nil {
        didSet {
            UserDefaults.standard.set(currentChannel, forKey: "currentChannel")
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

    @Published var path: NavigationPath = NavigationPath()
    
    init() {
        self.sessionToken = UserDefaults.standard.string(forKey: "sessionToken")
        self.currentServer = UserDefaults.standard.string(forKey: "currentServer")
        self.currentChannel = UserDefaults.standard.string(forKey: "currentChannel")
        self.currentSessionId = UserDefaults.standard.string(forKey: "currentSessionId")

        if let theme = UserDefaults.standard.data(forKey: "theme") {
            self.theme = try! JSONDecoder().decode(Theme.self, from: theme)
        } else {
            self.theme = Theme.light
        }

        self.http.token = self.sessionToken
        self.users["00000000000000000000000000"] = User(id: "00000000000000000000000000", username: "Revolt", discriminator: "0000")
    }

    class func preview() -> ViewState {
        let this = ViewState()
        this.state = .connected
        this.currentUser = User(id: "0", username: "Zomatree", discriminator: "0000", status: Status(text: "hello world", presence: "Busy"))
        this.users["0"] = this.currentUser!
        this.servers["0"] = Server(id: "0", name: "Testing Server", channels: ["0"], default_permissions: 0)
        this.channels["0"] = .text_channel(TextChannel(id: "0", server: "0", name: "General"))
        this.messages["01HD4VQY398JNRJY60JDY2QHA5"] = Message(id: "01HD4VQY398JNRJY60JDY2QHA5", content: "Hello World", author: "0", channel: "0", mentions: ["0"], replies: ["01HDEX6M2E3SHY8AC2S6B9SEAW"])
        this.messages["01HDEX6M2E3SHY8AC2S6B9SEAW"] = Message(id: "01HDEX6M2E3SHY8AC2S6B9SEAW", content: "reply", author: "0", channel: "0")
        this.channelMessages["0"] = ["01HD4VQY398JNRJY60JDY2QHA5", "01HDEX6M2E3SHY8AC2S6B9SEAW"]
        this.members["0"] = ["0": Member(id: MemberId(server: "0", user: "0"), joined_at: "")]
        this.currentServer = "0"
        this.currentChannel = "0"
        
        for i in (1...9) {
            this.users["\(i)"] = User(id: "i", username: "\(i)", discriminator: "\(i)\(i)\(i)\(i)")
        }
        
        this.currentlyTyping["0"] = ["0", "1", "2", "3", "4"]
        
        return this
    }

    func signIn(mfa_ticket: String, mfa_response: [String: String], callback: @escaping((LoginState) -> ())) async {
        let body = ["mfa_ticket": mfa_ticket, "mfa_response": mfa_response, "friendly_name": "Revolt IOS"] as [String : Any]
    
        await innerSignIn(body, callback)
    }
    
    func signIn(email: String, password: String, callback: @escaping((LoginState) -> ())) async {
        let body = ["email": email, "password": password, "friendly_name": "Revolt IOS"]

        await innerSignIn(body, callback)
    }
    
    private func innerSignIn(_ body: [String: Any], _ callback: @escaping((LoginState) -> ())) async {
        AF.request("https://api.revolt.chat/auth/session/login", method: .post, parameters: body, encoding: JSONEncoding.default)
            .responseData { response in
                switch response.result {
                    case .success(let data):
                        do {
                            let result = try JSONDecoder().decode(LoginResponse.self, from: data)
                            switch result {
                                case .Success(let success):
                                    self.currentSessionId = success._id
                                    self.sessionToken = success.token
                                    self.http.token = success.token
                                    return callback(.Success)
                                    
                                case .Mfa(let mfa):
                                    return callback(.Mfa(ticket: mfa.ticket, methods: mfa.allowed_methods))
                                    
                                case .Disabled:
                                    return callback(.Disabled)
                            }
                        } catch {}
                    case .failure(let err):
                        ()
                }
            }
    }

    func signOut() async -> Result<Bool, UserStateError>  {
        sessionToken = nil
        return .success(true)
    }
    
    func formatUrl(with: File) -> String {
        "\(apiInfo!.features.autumn.url)/\(with.tag)/\(with.id)"
    }
    
    func backgroundWsTask() async {
        if ws != nil {
            return
        }
        
        guard let token = sessionToken else {
            return
        }
        
        let apiInfo = try! await self.http.fetchApiInfo().get()
        self.http.apiInfo = apiInfo
        self.apiInfo = apiInfo

        let ws = WebSocketStream(url: apiInfo.ws, token: token, onEvent: onEvent)
        self.ws = ws
    }
    
    func queueMessage(channel: String, replies: [Reply], content: String, attachments: [(URL, String)]) async {
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
                for channel in event.channels {
                    channels[channel.id] = channel
                    channelMessages[channel.id] = []
                }
                
                for server in event.servers {
                    servers[server.id] = server
                    members[server.id] = [:]
                }
                
                for user in event.users {
                    if user.relationship == "User" {
                        currentUser = user
                    }
                    
                    users[user.id] = user
                }
                
                dms = try! await http.fetchDms().get()
                
                for dm in dms {
                    channelMessages[dm.id] = []
                }

                state = .connected

            case .message(let m):
                if users[m.author] == nil {
                    let user = try! await http.fetchUser(user: m.author).get()
                    users[m.author] = user
                }
    
                messages[m.id] = m
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
                
            case .channel_start_typing(let e):
                var typing = currentlyTyping.setDefault(key: e.channel, default: [])
                
                typing.append(e.id)
                
            case .channel_stop_typing(let e):
                currentlyTyping[e.channel]?.removeAll(where: { $0 == e.id })
                
            case .message_delete(let e):
                if var channel = channelMessages[e.channel] {
                    if let index = channel.firstIndex(of: e.id) {
                        channel.remove(at: index)
                        channelMessages[e.channel] = channel
                    }
                }
        }
    }
    
    func logout() {
        currentUser = nil
        sessionToken = nil
        currentServer = nil
        currentChannel = nil
        currentlyTyping = [:]
        currentSessionId = nil
        users = [:]
        servers = [:]
        channels = [:]
        messages = [:]
        channelMessages = [:]
        members = [:]
        dms = []
        path = NavigationPath()

        ws?.stop()
    }
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