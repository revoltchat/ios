//
//  Contents.swift
//  Revolt
//
//  Created by Angelo on 25/12/2023.
//

import Foundation
import SwiftUI
import Flow
import SwiftParsec

enum ContentPart: Equatable {
    case text(AttributedString)
    case user_mention(User, Member?)
    case channel_mention(Channel)
    case custom_emoji(Emoji)
}

enum Node {
    case user_mention(String)
    case channel_mention(String)
    case text(String)
    case custom_emoji(String)
}

let character = StringParser.character

func mentionTemplate(_ c: Character) -> GenericParser<String, (), String> {
    StringParser.noneOf("<@>")
        .many1
        .stringValue
        .between(
            character("<") *> character(c),
            character(">")
        )
}

let userMention = mentionTemplate("@").map(Node.user_mention)
let channelMention = mentionTemplate("#").map(Node.channel_mention)

let mention = userMention.attempt <|> channelMention.attempt

let emojiRaw = StringParser.noneOf(":").many1.stringValue.between(character(":"), character(":"))
let emoji = emojiRaw.map(Node.custom_emoji)
let customElement = mention <|> emoji

let text = (
    StringParser.anyCharacter.manyTill(customElement.attempt.lookAhead).attempt <|>
    StringParser.anyCharacter.many1)
    .stringValue.map(Node.text)

let node = customElement.attempt <|> text

let parser = node.many1
let emojiOnlyParser = emojiRaw.separatedBy1(character(" ").many).optional

func parseMentions(text: String) -> [Node] {
    // if it fails just default back to regular text
    (try? parser.run(sourceName: "<input>", input: text)) ?? [.text(text)]
}

func parseEmojisOnly(text: String) -> [String]? {
    (try? emojiOnlyParser.run(sourceName: "<input>", input: text)) ?? nil
}

struct Contents: View {
    @EnvironmentObject var viewState: ViewState

    var text: String
    
    @State var showMemberSheet: Bool = false
    
    func parseText(content: String, currentServer: String? = nil) -> [ContentPart] {
        var parts: [ContentPart] = []
        let content = try! AttributedString(markdown: content, options: .init(allowsExtendedAttributes: true,
interpretedSyntax: .full, failurePolicy: .returnPartiallyParsedIfPossible))
        
        for run in content.runs {
            let innerContent = content.characters[run.range].map { String($0) }.joined(separator: "")
            let innerParts = parseMentions(text: innerContent)
            
            for part in innerParts {
                switch part {
                    case .text(let c):
                        parts.append(.text(AttributedString(c, attributes: run.attributes)))
                    case .channel_mention(let id):
                        if let channel = viewState.channels[id] {
                            parts.append(.channel_mention(channel))
                        } else {
                            parts.append(.text(AttributedString("<#\(id)>", attributes: run.attributes)))
                        }
                    case .user_mention(let id):
                        if let user = viewState.users[id] {
                            let member: Member?
                            
                            if let server = currentServer {
                                member = viewState.members[server]?[id]
                            } else {
                                member = nil
                            }
                            
                            parts.append(.user_mention(user, member))
                        } else {
                            parts.append(.text(AttributedString("<@\(id)>", attributes: run.attributes)))
                        }
                    case .custom_emoji(let id):
                        if let emoji = viewState.emojis[id] {
                            parts.append(.custom_emoji(emoji))
                        } else {
                            parts.append(.text(AttributedString(":\(id):", attributes: run.attributes)))
                        }
                }
            }
        }
        
        return parts
    }
    
    func memberColour(member: Member?) -> Color? {
        return member.flatMap {
            let server = viewState.servers[$0.id.server]!
            return $0.displayColour(server: server)
        }
    }
    
    var body: some View {
        let parts = parseText(content: text)
    
        HFlow(spacing: 0) {
            let emojis = parts.compactMap { part -> Emoji? in
                if case .custom_emoji(let emoji) = part {
                    return emoji
                } else {
                    return nil
                }
            }
            
            if let emojis = parseEmojisOnly(text: text) {
                ForEach(emojis.compactMap { viewState.emojis[$0] }) { emoji in
                    LazyImage(source: .emoji(emoji.id), height: 32, width: 32, clipTo: Rectangle())
                }
            } else {
                ForEach(Array(parts.enumerated()), id: \.offset) { part in
                    switch part.element {
                        case .text(let attr):
                            Text(attr)
                        case .user_mention(let user, let member):
                            HStack(spacing: 2) {
                                Avatar(user: user, member: member, width: 16, height: 16)
                                Text(verbatim: member?.nickname ?? user.display_name ?? user.username)
                                    .bold()
                                    .foregroundStyle(memberColour(member: member) ?? viewState.theme.foreground.color)
                                
                            }
                            .contentShape(Capsule())
                            .onTapGesture {
                                showMemberSheet = true
                            }
                            .sheet(isPresented: $showMemberSheet) {
                                UserSheet(user: .constant(user), member: .constant(member))
                            }
                        case .channel_mention(let channel):
                            ChannelIcon(channel: channel, spacing: 0, initialSize: (14, 14), frameSize: (16, 16))
                                .bold()
                                .onTapGesture {
                                    viewState.currentServer = channel.server != nil ? .server(channel.server!) : .dms
                                    viewState.currentChannel = .channel(channel.id)
                                }
                        case .custom_emoji(let emoji):
                            LazyImage(source: .emoji(emoji.id), height: 16, width: 16, clipTo: Rectangle())
                    }
                }
            }
        }
    }
}

struct ParserPreview: PreviewProvider {
    static let viewState = ViewState.preview().applySystemScheme(theme: .light)
    
    static var previews: some View {
        VStack(alignment: .leading) {
            Contents(text: "# Hey <@0> check <#0> :0:")
            Contents(text: ":0: :0:")
        }
        .applyPreviewModifiers(withState: viewState)
    }
}
