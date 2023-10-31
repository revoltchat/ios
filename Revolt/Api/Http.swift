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
    var apiInfo: ApiInfo?
    var session: Alamofire.Session

    init(token: String?, baseURL: String) {
        self.token = token
        self.baseURL = baseURL
        self.apiInfo = nil
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
               
        print(response.result)
        return response.result.map({ b in try! JSONDecoder().decode(O.self, from: b.data(using: .utf8)!) })
    }
    
    func fetchSelf() async -> Result<User, AFError> {
        await req(method: .get, route: "/users/@me")
    }

    func fetchApiInfo() async -> Result<ApiInfo, AFError> {
        await req(method: .get, route: "/")
    }
    
    func sendMessage(channel: String, replies: [ApiReply], content: String, attachments: [(URL, String)], nonce: String) async -> Result<Message, AFError> {
        var attachmentIds: [String] = []
        
        for attachment in attachments {
            let body = await session.request(attachment.0)
                .serializingData()
                .response
                .data!
            
            let response = try! await uploadFile(data: body, name: attachment.1, category: .attachment).get()
            
            attachmentIds.append(response.id)
        }
        
        return await req(method: .post, route: "/channels/\(channel)/messages", parameters: SendMessage(replies: replies, content: content, attachments: attachmentIds))
    }
    
    func fetchUser(user: String) async -> Result<User, AFError> {
        await req(method: .get, route: "/users/\(user)")
    }
    
    func deleteMessage(channel: String, message: String) async -> Result<EmptyResponse, AFError> {
        let req = self.session.request(
            "\(baseURL)/channels/\(channel)/messages/\(message)",
            method: .delete,
            headers: token.map({ HTTPHeaders(dictionaryLiteral: ("x-session-token", $0)) })
        )
        
        let response = await req.serializingString()
            .response
        
        let code = response.response?.statusCode
        
        if ![200, 201, 202, 203, 204, 205, 206, 207, 208, 226].contains(code) {
            return Result.failure(AFError.responseSerializationFailed(reason: .inputFileNil))
        }
        
        return response.result.map({ _ in EmptyResponse() })
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
    
    func fetchDms() async -> Result<[Channel], AFError> {
        await req(method: .get, route: "/users/dms")
    }
    
    func fetchProfile(user: String) async -> Result<Profile, AFError> {
        await req(method: .get, route: "/users/\(user)/profile")
    }
    
    func uploadFile(data: Data, name: String, category: FileCategory) async -> Result<AutumnResponse, AFError> {
        let url = "\(apiInfo!.features.autumn.url)/\(category.rawValue)"

        return await session.upload(
            multipartFormData: { form in form.append(data, withName: "file", fileName: name)},
            to: url
        )
            .serializingDecodable(decoder: JSONDecoder())
            .response
            .result
    }
}

struct EmptyResponse: Decodable {
    
}

struct FetchHistory: Decodable {
    var messages: [Message]
    var users: [User]
    var members: [Member]?
}

struct ApiReply: Encodable {
    var id: String
    var mention: Bool
}

struct SendMessage: Encodable {
    var replies: [ApiReply]
    var content: String
    var attachments: [String]
}

struct AutumnResponse: Decodable {
    var id: String
}

struct AutumnPayload: Encodable {
    var file: Data
}
