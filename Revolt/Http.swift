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
    
        let response = await req.serializingString()
            .response
        
        let code = response.response?.statusCode
        
        if ![200, 201, 202, 203, 204, 205, 206, 207, 208, 226].contains(code) {
            return Result.failure(AFError.responseSerializationFailed(reason: .inputFileNil))
        }
                
        return response.result.map({ b in try! JSONDecoder().decode(O.self, from: b.data(using: .utf8)!) })
//            .serializingDecodable(O.self, emptyResponseCodes: [200])
//            .response
//            .result
    }
    
    func fetchSelf() async -> Result<User, AFError> {
        await req(method: .get, route: "/users/@me")
    }

    func fetchApiInfo() async -> Result<ApiInfo, AFError> {
        await req(method: .get, route: "/")
    }
    
    func sendMessage(channel: String, replies: [ApiReply], content: String, nonce: String) async -> Result<Message, AFError> {
        await req(method: .post, route: "/channels/\(channel)/messages", parameters: SendMessage(replies: replies, content: content))
    }
    
    func fetchUser(user: String) async -> Result<User, AFError> {
        await req(method: .get, route: "/users/\(user)")
    }
    
    func deleteMessage(channel: String, message: String) async -> Result<EmptyResponse, AFError> {
        await req(method: .delete, route: "/channels/\(channel)/messages/\(message)")
    }
    
    func fetchHistory(channel: String, limit: Int, before: String?) async -> Result<FetchHistory, AFError> {
        var url = "/channels/\(channel)/messages?limit=\(limit)&include_users=true"
        
        if let before = before {
            url = "\(url)&before=\(before)"
        }
        
        return await req(method: .get, route: url)
    }
    
    func fetchMessage(channel: String, message: String) async -> Result<Message, AFError> {
        await req(method: .get, route: "/channels/\(channel)/messages/\(message)")
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
