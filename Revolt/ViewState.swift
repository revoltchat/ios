import Foundation
import SwiftUI
import Alamofire

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
    @Published var users: Dictionary<String, User> = ["0": User(id: "0", username: "Zomatree", avatar: "https://avatars.githubusercontent.com/u/39768508")]
    @Published var servers: Dictionary<String, Server> = ["0": Server(id: "0", name: "Lounge", channels: ["0"])]
    @Published var channels: Dictionary<String, Channel> = ["0": TextChannel(id: "0", name: "General", description: "General channel yes yes very true so true")]
    @Published var messages: Dictionary<String, [Message]> = ["0": [
        Message(id: "0", content: "Hello world 0", author: "0", createdAt: Date.now, channel: "0"),
        Message(id: "1", content: "Hello world 1\n\n\nasdasdasdasdasd", author: "0", createdAt: Date.now, channel: "0"),
        Message(id: "2", content: "Hello world 2", author: "0", createdAt: Date.now, channel: "0"),
        Message(id: "3", content: "Hello world 3", author: "0", createdAt: Date.now, channel: "0"),
        Message(id: "4", content: "Hello world 4", author: "0", createdAt: Date.now, channel: "0"),
        Message(id: "5", content: "Hello world 5", author: "0", createdAt: Date.now, channel: "0"),
        Message(id: "6", content: "Hello world 6", author: "0", createdAt: Date.now, channel: "0"),
        Message(id: "7", content: "Hello world 7", author: "0", createdAt: Date.now, channel: "0"),
        Message(id: "8", content: "Hello world 8", author: "0", createdAt: Date.now, channel: "0"),
        Message(id: "9", content: "Hello world 9", author: "0", createdAt: Date.now, channel: "0"),
        Message(id: "10", content: "Hello world 10", author: "0", createdAt: Date.now, channel: "0")
    ]]

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
    }

    func signIn(email: String, password: String, callback: @escaping((LoginState) -> ())) async {
        let body = ["email": email, "password": password, "friendly_name": "Revolt IOS"]
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
                
                } catch {
                    print("error \(error)")
                }
                case .failure(let err):
                    print(err)
            }
        }
    }

    func signOut() async -> Result<Bool, UserStateError>  {
        sessionToken = ""
        return .success(true)
    }
    
    func backgroundWsTask() async {
        if ws != nil {
            return
        }
        
        guard let token = sessionToken else {
            return
        }
        
        let apiInfo = await self.http.fetchApiInfo()
        print(apiInfo)
        switch apiInfo {
            case .success(let info):
                self.apiInfo = info

                let ws = WebSocketStream(url: info.ws, token: token)
                print(ws)
                self.ws = ws
                        
            case .failure(let e):
                print(e)
        }
        
    }
}
