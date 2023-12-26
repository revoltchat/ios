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
}

enum Node {
    case user_mention(String)
    case channel_mention(String)
    case text(String)
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

let user_mention = mentionTemplate("@").map(Node.user_mention)
let channel_mention = mentionTemplate("#").map(Node.channel_mention)

let text = StringParser.anyCharacter.stringValue

let node = user_mention.attempt <|>
    channel_mention.attempt <|>
    text.map(Node.text)

let parser = node.many1

func parseMentions(text: String) -> [Node] {
    try! parser.run(sourceName: "<input>", input: text)
}

struct Contents: View {
    @EnvironmentObject var viewState: ViewState

    var text: String
    
    func parseText(content: String, currentServer: String? = nil) -> [ContentPart] {
        var parts: [ContentPart] = []
        let content = try! AttributedString(markdown: content)
        
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
                }
            }
        }
        
        return parts
    }
    
    var body: some View {
        let parts = parseText(content: text)
        HFlow(spacing: 0) {
            ForEach(Array(parts.enumerated()), id: \.offset) { part in
                switch part.element {
                    case .text(let text):
                        Text(text)
                    case .user_mention(let user, let member):
                        HStack(spacing: 2) {
                            Avatar(user: user, member: member, width: 16, height: 16)
                            Text(verbatim: member?.nickname ?? user.display_name ?? user.username)
                                .bold()
                        }
                        .contentShape(Capsule())
                        //.background(viewState.theme.background)
                    case .channel_mention(let channel):
                        ChannelIcon(channel: channel, spacing: 0, initialSize: (14.0, 14.0), frameSize: (16, 16))
                            .bold()
                }
            }
        }
    }
}

struct ParserPreview: PreviewProvider {
    static let viewState = ViewState.preview().applySystemScheme(theme: .light)
    
    static var previews: some View {
        Contents(text: "Hello <@0>, *checkout* <#0>!")
            .background(.white)
            .applyPreviewModifiers(withState: viewState)
    }
}
