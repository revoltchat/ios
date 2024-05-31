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
import Kingfisher
import Types

enum ContentPart: Equatable {
    case text(AttributedString)
    case user_mention(User, Member?)
    case channel_mention(Channel)
    case custom_emoji(String)
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
    [.text(text)]
    // (try? parser.run(sourceName: "<input>", input: text)) ?? [.text(text)]
}

func parseEmojisOnly(text: String) -> [String]? {
    (try? emojiOnlyParser.run(sourceName: "<input>", input: text)) ?? nil
}
//
//struct Contents: View {
//    @EnvironmentObject var viewState: ViewState
//
//    var text: String
//    
//    @State var showMemberSheet: Bool = false
//    
//    func parseText(content: String, currentServer: String? = nil) -> [ContentPart] {
//        var parts: [ContentPart] = []
//        let content = try! AttributedString(markdown: content, options: .init(allowsExtendedAttributes: true,
//interpretedSyntax: .full, failurePolicy: .returnPartiallyParsedIfPossible))
//        
//        for run in content.runs {
//            let innerContent = content.characters[run.range].map { String($0) }.joined(separator: "")
//            let innerParts = parseMentions(text: innerContent)
//            
//            for part in innerParts {
//                switch part {
//                    case .text(let c):
//                        parts.append(.text(AttributedString(c, attributes: run.attributes)))
//                    case .channel_mention(let id):
//                        if let channel = viewState.channels[id] {
//                            parts.append(.channel_mention(channel))
//                        } else {
//                            parts.append(.text(AttributedString("<#\(id)>", attributes: run.attributes)))
//                        }
//                    case .user_mention(let id):
//                        if let user = viewState.users[id] {
//                            let member: Member?
//                            
//                            if let server = currentServer {
//                                member = viewState.members[server]?[id]
//                            } else {
//                                member = nil
//                            }
//                            
//                            parts.append(.user_mention(user, member))
//                        } else {
//                            parts.append(.text(AttributedString("<@\(id)>", attributes: run.attributes)))
//                        }
//                    case .custom_emoji(let id):
//                        parts.append(.custom_emoji(id))
//                }
//            }
//        }
//        
//        return parts
//    }
//    
//    var body: some View {
//        let parts = parseText(content: text)
//        
//        GeometryReader { proxy in
//            if let emojis = parseEmojisOnly(text: text) {
//                ForEach(emojis, id: \.self) { emoji in
//                    LazyImage(source: .emoji(emoji), height: 32, width: 32, clipTo: Rectangle())
//                }
//            } else {
//                SubviewTextView(fixedWidth: proxy.size.width, parts: parts)
////                ForEach(Array(parts.enumerated()), id: \.offset) { part in
////                    switch part.element {
////                        case .text(let attr):
////                            Text(attr)
////                        case .user_mention(let user, let member):
////                            HStack(spacing: 2) {
////                                Avatar(user: user, member: member, width: 16, height: 16)
////                                Text(verbatim: member?.nickname ?? user.display_name ?? user.username)
////                                    .bold()
////                                    .foregroundStyle(memberColour(member: member) ?? viewState.theme.foreground.color)
////
////                            }
////                            .contentShape(Capsule())
////                            .onTapGesture {
////                                showMemberSheet = true
////                            }
////                            .sheet(isPresented: $showMemberSheet) {
////                                UserSheet(user: .constant(user), member: .constant(member))
////                            }
////                        case .channel_mention(let channel):
////                            ChannelIcon(channel: channel, spacing: 0, initialSize: (14, 14), frameSize: (16, 16))
////                                .bold()
////                                .onTapGesture {
////                                    viewState.currentServer = channel.server != nil ? .server(channel.server!) : .dms
////                                    viewState.currentChannel = .channel(channel.id)
////                                }
////                        case .custom_emoji(let emojiId):
////                            LazyImage(source: .emoji(emojiId), height: 16, width: 16, clipTo: Rectangle())
////                    }
////                }
//            }
//        }
//    }
//}

//
//struct SubviewTextView: UIViewRepresentable {
//    @EnvironmentObject var viewState: ViewState
//    
//    var fixedWidth: CGFloat
//    var parts: [ContentPart]
//    
//    func memberColour(member: Member?) -> Color? {
//        return member.flatMap {
//            let server = viewState.servers[$0.id.server]!
//            return $0.displayColour(server: server)
//        }
//    }
//    
//    func makeUIView(context: Context) -> some UIView {
//        let view = SubviewAttachingTextView()
//        view.textContainer.lineFragmentPadding = 0
//        view.textContainerInset = .zero
//
//        view.font = UIFont.preferredFont(forTextStyle: .body)
//        view.textColor = .white
//        view.backgroundColor = nil
//        view.isEditable = false
//        
//        view.translatesAutoresizingMaskIntoConstraints = false
//        view.isScrollEnabled = false
//        view.adjustsFontForContentSizeCategory = true
//        
//        view.setContentHuggingPriority(.required, for: .vertical)
//        view.setContentCompressionResistancePriority(.required, for: .vertical)
//        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
//        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
//        
//        let attrString = NSMutableAttributedString()
//                
//        for part in parts {
//            var view: (any View)? = nil
//            
//            switch part {
//                case .text(var str):
//                    str.foregroundColor = .white
//                    str.mergeAttributes(AttributeContainer([.foregroundColor: UIColor.white]))
//                    attrString.append(NSAttributedString(str))
//
//                case .channel_mention(let channel):
//                    view = ChannelIcon(channel: channel, spacing: 0, initialSize: (14, 14), frameSize: (16, 16))
//                        .bold()
//                        .onTapGesture {
//                            viewState.currentServer = channel.server != nil ? .server(channel.server!) : .dms
//                            viewState.currentChannel = .channel(channel.id)
//                        }
//
//                case .custom_emoji(let emoji):
//                    ()
//                    
//                case .user_mention(let user, let member):
//                    view = HStack(spacing: 2) {
//                        Avatar(user: user, member: member, width: 16, height: 16)
//                        Text(verbatim: member?.nickname ?? user.display_name ?? user.username)
//                            .bold()
//                            .foregroundStyle(memberColour(member: member) ?? viewState.theme.foreground.color)
//
//                    }
//                    .contentShape(Capsule())
//            }
//            
//            if let subView = view {
//                let controller = UIHostingController(rootView: AnyView(subView))
//                let nsAttrString = NSMutableAttributedString(attachment: SubviewTextAttachment(view: controller.view!))
//                attrString.append(NSAttributedString(string: " "))
//                attrString.append(nsAttrString)
//            }
//        }
//        view.attributedText = attrString
//        
//        return view
//    }
//    
//    func updateUIView(_ view: UIViewType, context: Context) {
//    }
//}

//struct Contents: View {
//    @EnvironmentObject var viewState: ViewState
//    
//    var text: String
//    
//    var body: some View {
//        Text(verbatim: text)
//    }
//}

//struct InnerContents: UIViewRepresentable {
//    var viewState: ViewState
//    var text: String
//        
//    func makeUIView(context: Context) -> some UIView {
//        let textView = UITextView()
//        
//        
//        textView.attributedText = NSAttributedString(str)
//        textView.backgroundColor = .clear
//        return textView
//    }
//    
//    func updateUIView(_ uiView: UIViewType, context: Context) {
//    }
//}

struct Contents: View {
    @EnvironmentObject var viewState: ViewState
    @Binding var text: String
    
    func buildContent() -> AttributedString {
        let font = UIFont.systemFont(ofSize: 15.0, weight: .regular)
                
        let parts = parseMentions(text: text)
        var str = AttributedString()
        
        for part in parts {
            switch part {
                case .user_mention(let string):
                    var mention: AttributedString = AttributedString()
                    let boldFont = UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize)
                    
                    if let user = viewState.users[string] {
                        let member = viewState.currentServer.id.flatMap { viewState.members[$0] }.flatMap { $0[string] }
                        
                        let name = member?.nickname ?? user.display_name ?? user.username
                                                                        
                        mention.append(AttributedString("@\(name)", attributes: AttributeContainer([.foregroundColor: UIColor(viewState.theme.accent.color), .font: boldFont, .link: "revoltchat://users?user=\(string)"])
))
                    } else {
                        let container = AttributeContainer([.foregroundColor: UIColor(viewState.theme.accent.color), .font: boldFont])
                        
                        mention.append(AttributedString("@Unknown", attributes: container))
                    }
                    
                    str.append(mention)
                    
                case .channel_mention(let string):
                    let mention: AttributedString
                    let boldFont = UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize)
                    
                    if let channel = viewState.channels[string] {
                        let name = channel.getName(viewState)
                        
                        let container = AttributeContainer([.foregroundColor: UIColor(viewState.theme.accent.color), .font: boldFont, .link: "revoltchat://channels?channel=\(string)"])
                        mention = AttributedString("#\(name)", attributes: container)
                    } else {
                        let container = AttributeContainer([.foregroundColor: UIColor(viewState.theme.accent.color), .font: boldFont])
                        
                        mention = AttributedString("#Unknown", attributes: container)
                    }
                    
                    str.append(mention)
                    
                case .text(let string):
                    var substring = try! AttributedString(markdown: string, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))
                    substring.setAttributes(AttributeContainer([.font: font, .foregroundColor: UIColor(viewState.theme.foreground.color)]))
                    
                    str.append(substring)
                    
                case .custom_emoji(let string):
                    str.append(AttributedString("<emoji>", attributes: AttributeContainer([.font: font])))
            }
        }
        
        return str
    }
    
    var body: some View {
        Text(buildContent())
    }
}

struct ParserPreview: PreviewProvider {
    static let viewState = ViewState.preview().applySystemScheme(theme: .light)
    
    static var previews: some View {
        Contents(text: .constant("hello <@0>, checkout <#0>!"))
            .applyPreviewModifiers(withState: viewState)
    }
}
