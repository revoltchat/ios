//
//  Websocket.swift
//  Revolt
//
//  Created by Zomatree on 21/04/2023.
//

import Foundation
import Starscream
import Types

enum WsMessage {
    case authenticated
    case invalid_session
    case ready(ReadyEvent)
    case message(Message)
    case message_update(MessageUpdateEvent)
    case channel_start_typing(ChannelTyping)
    case channel_stop_typing(ChannelTyping)
    case message_delete(MessageDeleteEvent)
    case channel_ack(ChannelAckEvent)
    case message_react(MessageReactEvent)
    case message_unreact(MessageReactEvent)
    case message_append(MessageAppend)
}

struct ReadyEvent: Decodable {
    var users: [User]
    var servers: [Types.Server]
    var channels: [Channel]
    var members: [Member]
    var emojis: [Emoji]
}

struct MessageUpdateEventData: Decodable {
    var content: String?
    var edited: String
}

struct MessageUpdateEvent: Decodable {
    var channel: String
    var id: String
    var data: MessageUpdateEventData
}

struct ChannelTyping: Decodable {
    var id: String
    var user: String
}

struct MessageDeleteEvent: Decodable {
    var channel: String
    var id: String
}

struct ChannelAckEvent: Decodable {
    var id: String
    var user: String
    var message_id: String
}

struct MessageReactEvent: Decodable {
    var id: String
    var channel_id: String
    var user_id: String
    var emoji_id: String
}

struct MessageAppend: Decodable {
    var id: String
    var channel: String
    var append: Embed
}

extension WsMessage: Decodable {
    enum CodingKeys: String, CodingKey { case type }
    enum Tag: String, Decodable { case Authenticated, InvalidSession, Ready, Message, MessageUpdate, ChannelStartTyping, ChannelStopTyping, MessageDelete, ChannelAck, MessageReact, MessageUnreact, MessageAppend }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let singleValueContainer = try decoder.singleValueContainer()
        
        switch try container.decode(Tag.self, forKey: .type) {
            case .Authenticated:
                self = .authenticated
            case .InvalidSession:
                self = .invalid_session
            case .Ready:
                self = .ready(try singleValueContainer.decode(ReadyEvent.self))
            case .Message:
                self = .message(try singleValueContainer.decode(Message.self))
            case .MessageUpdate:
                self = .message_update(try singleValueContainer.decode(MessageUpdateEvent.self))
            case .ChannelStartTyping:
                self = .channel_start_typing(try singleValueContainer.decode(ChannelTyping.self))
            case .ChannelStopTyping:
                self = .channel_stop_typing(try singleValueContainer.decode(ChannelTyping.self))
            case .MessageDelete:
                self = .message_delete(try singleValueContainer.decode(MessageDeleteEvent.self))
            case .ChannelAck:
                self = .channel_ack(try singleValueContainer.decode(ChannelAckEvent.self))
            case .MessageReact:
                self = .message_react(try singleValueContainer.decode(MessageReactEvent.self))
            case .MessageUnreact:
                self = .message_unreact(try singleValueContainer.decode(MessageReactEvent.self))
            case .MessageAppend:
                self = .message_append(try singleValueContainer.decode(MessageAppend.self))
        }
    }
}

enum WsState {
    case disconnected
    case connecting
    case connected
}

class SendWsMessage: Encodable {
    var type: String
    
    init(type: String) {
        self.type = type
    }
}

class Authenticate: SendWsMessage, CustomStringConvertible {
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
    
    var description: String {
        return "Authenticate(token: \(token))"
    }
}

class WebSocketStream: ObservableObject {
    private var url: URL
    private var client: WebSocket
    private var encoder: JSONEncoder
    private var decoder: JSONDecoder
    private var onEvent: (WsMessage) async -> ()

    public var token: String
    @Published public var currentState: WsState = .disconnected
    public var retryCount: Int = 0

    init(url: String, token: String, onEvent: @escaping (WsMessage) async -> ()) {
        self.token = token
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.onEvent = onEvent
        self.url = URL(string: url)!
        
        let request = URLRequest(url: self.url)
        let ws = WebSocket(request: request)
        client = ws

        ws.onEvent = didReceive
        ws.connect()
    }

    public func stop() {
        client.disconnect(closeCode: .zero)
    }
    
    public func didReceive(event: WebSocketEvent) {
        switch event {
            case .connected(_):
                currentState = .connecting
                let payload = Authenticate(token: token)
                print(payload.description)

                let s = try! encoder.encode(payload)
                client.write(string: String(data: s, encoding: .utf8)!)
                    
            case .disconnected(let reason, _):
                print("disconnect \(reason)")
                currentState = .disconnected
                
                Task {
                    await tryReconnect()
                }

            case .text(let string):

                do {
                    let e = try decoder.decode(WsMessage.self, from: string.data(using: .utf8)!)

                    Task {
                        await onEvent(e)
                    }
                } catch {
                    print(error)
                }
                
            case .viabilityChanged(let viability):
                if !viability {
                    currentState = .disconnected
                    Task {
                        await tryReconnect()
                    }
                }

            case .error(let error):
                currentState = .disconnected
                self.stop()
                print("error \(String(describing: error))")
                
                Task {
                    await tryReconnect()
                }
            default:
                break
        }
    }
    
    func forceConnect() {
        let request = URLRequest(url: self.url)
        let ws = WebSocket(request: request)
        
        client = ws
        
        ws.onEvent = didReceive
        ws.connect()
    }
    
    func tryReconnect() async {
        let sleep = 0.25 * Double(pow(Double(2), Double(retryCount - 1)))
        try! await Task.sleep(for: .seconds(sleep))
        
        currentState = .connecting
        
        forceConnect()
        
        retryCount += 1
    }
}
