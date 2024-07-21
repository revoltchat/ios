//
//  Contents.swift
//  Revolt
//
//  Created by Angelo on 25/12/2023.
//

import Foundation
import SwiftUI
import Flow
// import Parsing
import Kingfisher
import Types
import SwiftParsec

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

//
//let userMention = Parse(input: Substring.self) { id in
//    Node.user_mention(String(id))
//} with: {
//    "<@"
//    Prefix { $0 != ">" }
//    ">"
//}
//
//let channelMention = Parse(input: Substring.self) { id in
//    Node.channel_mention(String(id))
//} with: {
//    "<#"
//    Prefix { $0 != ">" }
//    ">"
//}
//let mention = Parse(input: Substring.self) {
//    OneOf {
//        userMention
//        channelMention
//    }
//}
//
//let emoji = Parse(input: Substring.self) { id in
//    Node.custom_emoji(String(id))
//} with: {
//    ":"
//    Prefix { $0 != ":" }
//    ":"
//}
//
//let parser = Parse(input: Substring.self) {
//    Many {
//        Optionally {
//            Many {
//                OneOf {
//                    mention
//                    emoji
//                }
//            }
//        }
//        Prefix { !["@", ":"].contains(String($0)) }.map { v in Node.text(String(v)!) }
//    }
//    Many {
//        Parse {
//            Optionally {
//                OneOf {
//                    mention
//                    emoji
//                }
//            }
//        }
//        Optionally {
//            OneOf {
//                mention
//                emoji
//            }
//        }
//    }.map { nodes in
//        nodes.flatMap { (a, b, c) in
//            [a, b, c].compactMap { $0 }
//        }
//    }
//}

//func parseMentions(text: String) -> [Node] {
//    // if it fails just default back to regular text
//    //[.text(text)]
//    print(text)
//    return try! parser.parse(text)
//}

// if you need to properly debug this the haskell code for this is here:
/*
data Node = Text String | Emoji String | UserMention String | ChannelMention String
deriving Show

emoji :: GenParser Char () Node
emoji = Emoji <$> (char ':' *> many1 (noneOf ":") <* char ':')

mentionTemplate :: (String -> b) -> Char -> GenParser Char () b
mentionTemplate f c = f <$> (char '<' *> char c *> many1 (noneOf ">") <* char '>')

userMention :: GenParser Char () Node
userMention =  mentionTemplate UserMention '@'

channelMention :: GenParser Char () Node
channelMention = mentionTemplate UserMention '#'

mention :: GenParser Char () Node
mention = try userMention <|> channelMention

customElement :: GenParser Char () Node
customElement = try emoji <|> mention

text :: GenParser Char () Node
text = Text <$> liftA2 (:) anyChar (manyTill anyChar (lookAhead $ eof <|> void (try customElement)))

node :: GenParser Char () Node
node = try customElement <|> text

parser :: GenParser Char () [Node]
parser = many1 node
*/

let character = StringParser.character

func mentionTemplate(_ c: Character) -> GenericParser<String, (), String> {
    character("<")
    *> character(c)
    *> StringParser.noneOf(["<", c, ">"])
        .many1
        .stringValue
    <* character(">")
}

let userMention = Node.user_mention <^> mentionTemplate("@")
let channelMention = Node.channel_mention <^> mentionTemplate("#")

let mention = userMention.attempt <|> channelMention

let emojiRaw = character(":")
    *> StringParser.noneOf(":")
        .many1
        .stringValue
    <* character(":")

let emoji = Node.custom_emoji <^> emojiRaw

let customElement = mention.attempt <|> emoji

let text = StringParser.anyCharacter >>- { result in
    StringParser.anyCharacter.manyTill((StringParser.eof <|> customElement.attempt.discard).lookAhead) >>- { results in
        return GenericParser(
            result: Node.text(String(results.prepending(result)))
        )
    }
}

let node = customElement.attempt <|> text

let parser = node.many1
let emojiOnlyParser = emojiRaw.separatedBy1(character(" ").many).optional

func parseMentions(text: String) -> [Node] {
    // if it fails just default back to regular text
    // [.text(text)]
    return (try? parser.run(sourceName: "<input>", input: text)) ?? [.text(text)]
}

func parseEmojisOnly(text: String) -> [String]? {
    (try? emojiOnlyParser.run(sourceName: "<input>", input: text)) ?? nil
}

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

//struct _Contents: View {
//    @State var images: [String: UIImage] = [:]
//
//    func loadImage(url: String) -> UIImage {
//        if let image = images[url] {
//            return image
//        } else {
//            Task {
//
//            }
//        }
//    }
//
//    var body: some View {
//        let font = UIFont.preferredFont(forTextStyle: .title1)
//        let nsattr = NSAttributedString(string: "Zomatree", attributes: [.foregroundColor: UIColor.red, .font: font, .link: "https://revolt.chat"])
//        let attr = AttributedString(nsattr)
//        let large = UIImage(named: "large")!
//        let image = Image(uiImage: large.imageWith(newSize: CGSize(width: font.pointSize, height: font.pointSize)))
//
//        (
//            Text("Hello ") +
//            Text(image) +
//            Text(attr) +
//            Text(".")
//        ).font(.title)
//    }
//}


struct Contents: View {
    @EnvironmentObject var viewState: ViewState
    @Binding var text: String
    @State var images: [URL: UIImage] = [:]
    var fontSize: CGFloat
    
    func addImageToState(url: URL, image: UIImage, round: Bool) {
        let image = round ? image.roundedImage : image

        images[url] = image.imageWith(newSize: CGSize(width: fontSize, height: fontSize), contentMode: .contentAspectFit)
    }
    
    func getImage(url: URL, round: Bool = false) -> UIImage {
        if let image = images[url] {
            return image
        } else {
            Task {
                ImageCache.default.retrieveImage(forKey: url.absoluteString, options: []) { cacheResult in
                    if case .success(let cacheImage) = cacheResult,
                       let image = cacheImage.image
                    {
                        addImageToState(url: url, image: image, round: round)
                    } else {
                        ImageDownloader.default.downloadImage(with: url, options: []) { result in
                            if case .success(let image) = result,
                               let image = UIImage(data: image.originalData)
                            {
                                ImageCache.default.store(image, forKey: url.absoluteString, options: .init([]))
                                addImageToState(url: url, image: image, round: round)
                            }
                        }
                    }
                }
            }
            
            return UIImage()
        }
    }

    func buildContent() -> Text? {
        let font = UIFont.systemFont(ofSize: fontSize)
        let boldFont = UIFont.boldSystemFont(ofSize: fontSize)

        let parts = parseMentions(text: text)
        var textParts: [Text] = []

        for part in parts {
            switch part {
                case .user_mention(let string):
                    if let user = viewState.users[string] {
                        let member = viewState.currentServer.id.flatMap { viewState.members[$0] }.flatMap { $0[string] }

                        let name = member?.nickname ?? user.display_name ?? user.username

                        let mention = NSAttributedString(string: name, attributes: [.foregroundColor: viewState.theme.accent.color, .font: boldFont, .link: "revoltchat://users?user=\(string)"])
                        let pfpUrl = (member?.avatar ?? user.avatar).map { viewState.formatUrl(with: $0) } ?? "\(viewState.http.baseURL)/users/\(user.id)/default_avatar"
                        
                        let image = getImage(url: URL(string: pfpUrl)!, round: true)
                        let text = Text(Image(uiImage: image)) + Text(AttributedString(mention))
                        
                        textParts.append(text)
                    } else {
                        textParts.append(Text(AttributedString(NSAttributedString(string: "@Unknown", attributes: [.foregroundColor: viewState.theme.accent.color, .font: boldFont]))))
                    }
                case .channel_mention(let string):
                    let mention: NSAttributedString

                    if let channel = viewState.channels[string] {
                        let name = channel.getName(viewState)

                        mention = NSAttributedString(string: "#\(name)", attributes: [.foregroundColor: viewState.theme.accent.color, .font: boldFont, .link: "revoltchat://channels?channel=\(string)"])
                    } else {
                        mention = NSAttributedString(string: "#Unknown", attributes: [.foregroundColor: viewState.theme.accent.color, .font: boldFont])
                    }

                    textParts.append(Text(AttributedString(mention)))

                case .text(let string):
                    if string.count > 0 {
                        let substring = try! NSMutableAttributedString(markdown: string, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))
                        substring.setAttributes([.font: font, .foregroundColor: viewState.theme.foreground.color], range: NSRange(location: 0, length: substring.length))

                        textParts.append(Text(AttributedString(substring)))
                    }

                case .custom_emoji(let id):
                    let url = viewState.formatUrl(fromEmoji: id)
                    let image = getImage(url: URL(string: url)!)
                    
                    textParts.append(Text(Image(uiImage: image)))
            }
        }

        if textParts.count > 0 {
            let first = textParts.removeFirst()
            return textParts.reduce(first, (+))
        } else {
            return nil
        }
    }

    var body: some View {
        if let text = buildContent() {
            text
        }
    }
}

struct ParserPreview: PreviewProvider {
    static let viewState = ViewState.preview().applySystemScheme(theme: .light)

    static var previews: some View {
        Contents(text: .constant("hello <@0>, checkout <#0>!"), fontSize: 16)
            .applyPreviewModifiers(withState: viewState)
    }
}
