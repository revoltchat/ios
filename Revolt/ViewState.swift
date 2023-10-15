import Foundation
import SwiftUI
import Alamofire
import ULID

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
    @Published var user: User? = nil
    @Published var users: Dictionary<String, User> = [:]
    @Published var servers: Dictionary<String, Server> = [:]
    @Published var channels: Dictionary<String, Channel> = [:]
    @Published var messages: Dictionary<String, [Message]> = [:]
    @Published var members: Dictionary<String, Dictionary<String, Member>> = [:]
    
    @Published var state: ConnectionState = .connecting
    @Published var queuedMessages: Dictionary<String, [QueuedMessage]> = [:]
    @Published var currentUser: User? = nil

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

    init() {
        self.sessionToken = UserDefaults.standard.string(forKey: "sessionToken")
        self.currentServer = UserDefaults.standard.string(forKey: "currentServer")
        self.currentChannel = UserDefaults.standard.string(forKey: "currentChannel")
        self.http.token = self.sessionToken
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
        
        let apiInfo = await self.http.fetchApiInfo()

        switch apiInfo {
            case .success(let info):
                self.apiInfo = info

                let ws = WebSocketStream(url: info.ws, token: token, onEvent: onEvent)
                self.ws = ws
                        
            case .failure(let e):
                print(e)
        }
        
    }
    
    func queueMessage(channel: String, replies: [Reply], content: String) async {
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
        
        await http.sendMessage(channel: channel, replies: r, content: content, nonce: nonce)
    }

    func onEvent(_ event: WsMessage) async {
        switch event {
            case .ready(let event):
                for channel in event.channels {
                    channels[channel.id()] = channel
                    messages[channel.id()] = []
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
                
                state = .connected

            case .message(let m):
                if users[m.author] == nil {
                    user = try! await http.fetchUser(user: m.author).get()
                    users[m.author] = user
                }
    
                messages[m.channel]?.append(m)

            case .message_update(let event):
                let message = messages[event.channel]?.reversed().first(where: { $0.id == event.id })
                
                if var message = message {
                    message.edited = event.data.edited

                    if let content = event.data.content {
                        message.content = content
                        print(content)
                    }
                }
                
            default:
                ()
        }
    }
}
