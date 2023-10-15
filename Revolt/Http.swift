//
//  Http.swift
//  Revolt
//
//  Created by Zomatree on 21/04/2023.
//

import Foundation
import Alamofire

struct HTTPClient {
    var token: String?
    var baseURL: String
    var session: Alamofire.Session

    init(token: String?, baseURL: String) {
        self.token = token
        self.baseURL = baseURL
        self.session = Alamofire.Session()
    }

    func req<
        I: Encodable,
        O: Decodable
    >(
        method: HTTPMethod,
        route: String,
        parameters: I? = nil as Int?,
        encoder: ParameterEncoder = JSONParameterEncoder.default
    ) async -> Result<O, AFError> {
        let req = self.session.request(
            "\(baseURL)\(route)",
            method: method,
            parameters: parameters,
            encoder: encoder,
            headers: token.map({ HTTPHeaders(dictionaryLiteral: ("x-session-token", $0)) })
        )
    
        let body = await req.serializingString()
            .response
            .result
                
        return body.map({ b in try! JSONDecoder().decode(O.self, from: b.data(using: .utf8)!) })
//            .serializingDecodable(O.self, emptyResponseCodes: [200])
//            .response
//            .result
    }
    
    func fetchSelf() async -> Result<User, AFError> {
        return await req(method: .get, route: "/users/@me")
    }
    
    func fetchApiInfo() async -> Result<ApiInfo, AFError> {
        return await req(method: .get, route: "/")
    }
    
    func sendMessage(channel: String, replies: [ApiReply], content: String, nonce: String) async -> Result<Message, AFError> {
        return await req(method: .post, route: "/channels/\(channel)/messages", parameters: SendMessage(replies: replies, content: content))
    }
    
    func fetchUser(user: String) async -> Result<User, AFError> {
        return await req(method: .get, route: "/users/\(user)")
    }
    
    func deleteMessage(channel: String, message: String) async -> Result<EmptyResponse, AFError> {
        await req(method: .delete, route: "/channels/\(channel)/messages/\(message)")
    }
    
    func fetchHistory(channel: String, limit: Int, before: String?) async -> Result<FetchHistory, AFError> {
        var url = "/channels/\(channel)/messages?limit=\(limit)&include_users=true"
        
        if let before = before {
            url = "\(url)&before=\(before)"
        }
        
        print(url)
        return await req(method: .get, route: url)
    }
}

struct EmptyResponse: Decodable {
    
}

struct FetchHistory: Decodable {
    var messages: [Message]
    var users: [User]
    var members: [Member]
}

struct ApiReply: Encodable {
    var id: String
    var mention: Bool
}

struct SendMessage: Encodable {
    var replies: [ApiReply]
    var content: String
}
