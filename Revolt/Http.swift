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

    func req<I: Encodable, O: Decodable>(method: HTTPMethod, route: String, json: I? = nil as Int?) async -> Result<O, AFError> {
        return await self.session.request(
            "\(baseURL)\(route)",
            method: method,
            parameters: json,
            encoder: JSONParameterEncoder.default,
            headers: token.map({ HTTPHeaders(dictionaryLiteral: ("x-session-token", $0)) })
        )
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
}
