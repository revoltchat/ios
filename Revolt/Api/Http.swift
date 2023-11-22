//
//  Http.swift
//  Revolt
//
//  Created by Zomatree on 21/04/2023.
//

import Foundation
import Alamofire
import os

struct HTTPClient {
    var token: String?
    var baseURL: String
    var apiInfo: ApiInfo?
    var session: Alamofire.Session
    var logger: Logger

    init(token: String?, baseURL: String) {
        self.token = token
        self.baseURL = baseURL
        self.apiInfo = nil
        self.session = Alamofire.Session()
        self.logger = Logger(subsystem: "chat.revolt.Revolt", category: "HTTP")
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
        
        let code = response.response?.statusCode ?? 500
        
        do {
            let resp = try response.result.get()
            logger.debug("Received response \(code) for route \(method.rawValue) \(baseURL)\(route) with result \(resp)")
        } catch {
            logger.debug("Received response \(code) for route \(method.rawValue) \(baseURL)\(route) with bad result \(response.error)")
        }

        if ![200, 201, 202, 203, 204, 205, 206, 207, 208, 226].contains(code) {
            return Result.failure(AFError.responseSerializationFailed(reason: .inputFileNil))
        }
               
        return response.result.map({ b in try! JSONDecoder().decode(O.self, from: b.data(using: .utf8)!) })
    }

    func req<
        I: Encodable
    >(
        method: HTTPMethod,
        route: String,
        parameters: I? = nil as Int?,
        encoder: ParameterEncoder = JSONParameterEncoder.default
    ) async -> Result<EmptyResponse, AFError> {
        let req = self.session.request(
            "\(baseURL)\(route)",
            method: method,
            parameters: parameters,
            encoder: encoder,
            headers: token.map({ HTTPHeaders(dictionaryLiteral: ("x-session-token", $0)) })
        )
        
        let response = await req.serializingString()
            .response
        
        let code = response.response?.statusCode ?? 500
        
        logger.debug("Received response \(code) for route \(method.rawValue) \(baseURL)\(route) with result \(try! response.result.get())")

        
        if ![200, 201, 202, 203, 204, 205, 206, 207, 208, 226].contains(code) {
            return Result.failure(AFError.responseSerializationFailed(reason: .inputFileNil))
        }
        
        return response.result.map({ _ in EmptyResponse() })
    }
    
    func fetchSelf() async -> Result<User, AFError> {
        await req(method: .get, route: "/users/@me")
    }

    func fetchApiInfo() async -> Result<ApiInfo, AFError> {
        await req(method: .get, route: "/")
    }
    
    func sendMessage(channel: String, replies: [ApiReply], content: String, attachments: [(Data, String)], nonce: String) async -> Result<Message, AFError> {
        var attachmentIds: [String] = []
        
        for attachment in attachments {
            let response = try! await uploadFile(data: attachment.0, name: attachment.1, category: .attachment).get()
            
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
    
    func fetchSessions() async -> Result<[Session], AFError> {
        await req(method: .get, route: "/auth/session/all")
    }
    
    func deleteSession(session: String) async -> Result<EmptyResponse, AFError> {
        await req(method: .delete, route: "/auth/session/\(session)")
    }
    
    func joinServer(code: String) async -> Result<JoinResponse, AFError> {
        await req(method: .post, route: "/invites/\(code)")
    }
    
    func reportMessage(id: String, reason: ContentReportPayload.ContentReportReason, userContext: String) async -> Result<EmptyResponse, AFError> {
        await req(method: .post, route: "/safety/report", parameters: ContentReportPayload(type: .Message, contentId: id, reason: reason, userContext: userContext))
    }
    
    func createAccount(email: String, password: String, invite: String?, captcha: String?) async -> Result<EmptyResponse, AFError> {
        return await req(method: .post, route: "/auth/account/create", parameters: AccountCreatePayload(email: email, password: password, invite: invite, captcha: captcha))
    }
    
    func createAccount_VerificationCode(code: String) async -> Result<AccountCreateVerifyResponse, AFError> {
        await req(method: .post, route: "/auth/account/verify/\(code)")
    }
    
    func createAccount_ResendVerification(email: String, captcha: String?) async -> Result<EmptyResponse, AFError> {
        await req(method: .post, route: "/auth/account/reverify", parameters: ["email": email, "captcha": captcha])
    }
    
    func sendResetPasswordEmail(email: String, captcha: String?) async -> Result<EmptyResponse, AFError> {
        await req(method: .post, route: "/auth/account/reverify", parameters: ["email": email, "captcha": captcha])
    }
    
    func resetPassword(token: String, password: String, removeSessions: Bool = false) async -> Result<EmptyResponse, AFError> {
        await req(method: .patch, route: "/auth/account/reset_password", parameters: PasswordResetPayload(token: token, password: password))
    }
    
    func checkOnboarding() async -> Result<OnboardingStatusResponse, AFError> {
        await req(method: .get, route: "/onboard/hello")
    }
    
    func completeOnboarding(username: String) async -> Result<EmptyResponse, AFError> {
        await req(method: .post, route: "/onboard/complete", parameters: ["username": username])
    }
    
    func acceptFriendRequest(user: String) async -> Result<User, AFError> {
        await req(method: .put, route: "/users/\(user)/friend")
    }
    
    func removeFriend(user: String) async -> Result<User, AFError> {
        await req(method: .delete, route: "/users/\(user)/friend")
    }
    
    func blockUser(user: String) async -> Result<User, AFError> {
        await req(method: .put, route: "/users/\(user)/block")
    }
    
    func unblockUser(user: String) async -> Result<User, AFError> {
        await req(method: .delete, route: "/users/\(user)/block")
    }
    
    func sendFriendRequest(username: String) async -> Result<User, AFError> {
        await req(method: .post, route: "/users/friend", parameters: ["username": username])
    }
    
    func openDm(user: String) async -> Result<Channel, AFError> {
        await req(method: .get, route: "/users/\(user)/dm")
    }
}
