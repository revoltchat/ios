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
        json: I? = nil as Int?
    ) async -> Result<O, AFError> {
        await self.session.request(
            "\(baseURL)\(route)",
            method: method,
            parameters: json,
            encoder: JSONParameterEncoder.default,
            headers: token.map({ HTTPHeaders(dictionaryLiteral: ("x-session-token", $0)) })
        )
//        .serializingString()
//        .response
//        .result
//        
//        print(body)
//        
//        return body.map({ b in try! JSONDecoder().decode(O.self, from: b.data(using: .utf8)!) })
            .serializingDecodable(O.self, emptyResponseCodes: [200])
            .response
            .result
    }
    
    func fetchSelf() async -> Result<User, AFError> {
        return await req(method: .get, route: "/users/@me")
    }
    
    func fetchApiInfo() async -> Result<ApiInfo, AFError> {
        return await req(method: .get, route: "/")
    }
    
    func sendMessage(channel: String, replies: [ApiReply], content: String, nonce: String) async -> Result<Message, AFError> {
        return await req(method: .post, route: "/channels/\(channel)/messages", json: SendMessage(replies: replies, content: content))
    }
    
    func fetchUser(user: String) async -> Result<User, AFError> {
        return await req(method: .get, route: "/users/\(user)")
    }
}

struct ApiReply: Encodable {
    var id: String
    var mention: Bool
}

struct SendMessage: Encodable {
    var replies: [ApiReply]
    var content: String
}
