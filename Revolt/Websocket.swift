//
//  Websocket.swift
//  Revolt
//
//  Created by Zomatree on 21/04/2023.
//

import Foundation
import Starscream

struct WsMessage: Codable {
    
}

enum WsState {
    case Disconnected
    case Connecting
    case Connected
}

class SendWsMessage: Encodable {
    var type: String
    
    init(type: String) {
        self.type = type
    }
}

class Authenticate: SendWsMessage {
    private enum CodingKeys: String, CodingKey { case type, token }

    var token: String
    
    init(token: String) {
        self.token = token
        super.init(type: "Authenticate")
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(token, forKey: .token)
        try container.encode(type, forKey: .type)
    }
}

class WebSocketStream {
    private var client: WebSocket
    private var encoder: JSONEncoder
    private var decoder: JSONDecoder

    public var token: String
    public var currentState: WsState = .Disconnected

    init(url: String, token: String) {
        self.token = token
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()

        let url = URL(string: url)!
        let request = URLRequest(url: url)

        let ws = WebSocket(request: request)
        client = ws

        ws.onEvent = didReceive
        ws.connect()

        client = ws
    }

    public func didReceive(event: WebSocketEvent) {
        print(event)
        switch event {
            case .connected(_):
                currentState = .Connecting
                let payload = Authenticate(token: token)
                do {
                    let s = try encoder.encode(payload)
                    client.write(data: s)
                } catch {
                    print(error)
                }
                    
            case .disconnected(let reason, let _):
                print(reason)
                currentState = .Disconnected
            case .text(let string):
                print(string)
            case .error(let error):
                print(error)
            default:
                break
        }
    }
}
