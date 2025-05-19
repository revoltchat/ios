//
//  Contents.swift
//  Revolt
//
//  Created by Angelo on 25/12/2023.
//

import Foundation
import SwiftUI
// import Flow
// import Parsing
import Kingfisher
import Types
// import SwiftParsec
import SubviewAttachingTextView
import SnapKit
import UIKit
import Highlightr

//enum ContentPart: Equatable {
//    case text(AttributedString)
//    case user_mention(User, Member?)
//    case channel_mention(Channel)
//    case custom_emoji(String)
//}
//
//enum Node {
//    case user_mention(String)
//    case channel_mention(String)
//    case text(String)
//    case custom_emoji(String)
//}

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
//
//let character = StringParser.character
//
//func mentionTemplate(_ c: Character) -> GenericParser<String, (), String> {
//    character("<")
//    *> character(c)
//    *> StringParser.noneOf(["<", c, ">"])
//        .many1
//        .stringValue
//    <* character(">")
//}
//
//let userMention = Node.user_mention <^> mentionTemplate("@")
//let channelMention = Node.channel_mention <^> mentionTemplate("#")
//
//let mention = userMention.attempt <|> channelMention
//
//let emojiRaw = character(":")
//    *> StringParser.noneOf(":")
//        .many1
//        .stringValue
//    <* character(":")
//
//let emoji = Node.custom_emoji <^> emojiRaw
//
//let customElement = mention.attempt <|> emoji
//
//let text = StringParser.anyCharacter >>- { result in
//    StringParser.anyCharacter.manyTill((StringParser.eof <|> customElement.attempt.discard).lookAhead) >>- { results in
//        return GenericParser(
//            result: Node.text(String(results.prepending(result)))
//        )
//    }
//}
//
//let node = customElement.attempt <|> text
//
//let parser = node.many1
//let emojiOnlyParser = emojiRaw.separatedBy1(character(" ").many).optional
//
//nonisolated func parseMentions(text: String) -> [Node] {
//    // if it fails just default back to regular text
//    // [.text(text)]
//    return (try? parser.run(sourceName: "<input>", input: text)) ?? [.text(text)]
//}
//
//func parseEmojisOnly(text: String) -> [String]? {
//    (try? emojiOnlyParser.run(sourceName: "<input>", input: text)) ?? nil
//}

//struct Contents: View {
//    @EnvironmentObject var viewState: ViewState
//
//    var text: String
//
//    @State var showMemberSheet: Bool = false
//
//    func parseText(content: String, currentSelection: String? = nil) -> [ContentPart] {
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
//                            if let server = currentSelection {
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
////                                    viewState.currentSelection = channel.server != nil ? .server(channel.server!) : .dms
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
//                            viewState.currentSelection = channel.server != nil ? .server(channel.server!) : .dms
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


//struct Contents: View {
//    @EnvironmentObject var viewState: ViewState
//    @Binding var text: String
//    
//    var lock: NSRecursiveLock = NSRecursiveLock()
//    @State var images: [URL: UIImage] = [:]
//    
//    @State var cached: Text? = nil
//    @State var loading: Bool = false
//    
//    var fontSize: CGFloat
//    
//    func addImageToState(url: URL, image: UIImage, round: Bool) {
//        var image = round ? image.roundedImage : image
//
//        image = image.imageWith(newSize: CGSize(width: fontSize, height: fontSize), contentMode: .contentAspectFit)!
//        
//        lock.withLock { images[url] = image }
//    }
//    
//    func getImage(url: URL, round: Bool = false) -> UIImage {
//        if let image = lock.withLock({ images[url] }) {
//            return image
//        } else {
//            Task {
//                ImageCache.default.retrieveImage(forKey: url.absoluteString, options: []) { cacheResult in
//                    if case .success(let cacheImage) = cacheResult,
//                       let image = cacheImage.image
//                    {
//                        addImageToState(url: url, image: image, round: round)
//                    } else {
//                        ImageDownloader.default.downloadImage(with: url, options: []) { result in
//                            if case .success(let image) = result,
//                               let image = UIImage(data: image.originalData)
//                            {
//                                ImageCache.default.store(image, forKey: url.absoluteString, options: .init([]))
//                                addImageToState(url: url, image: image, round: round)
//                            }
//                        }
//                    }
//                }
//            }
//            
//            return UIImage().imageWith(newSize: CGSize(width: fontSize, height: fontSize))
//        }
//    }
//
//    func buildContent(parts: [Node]) -> Text? {
//        let font = UIFont.systemFont(ofSize: fontSize)
//        let boldFont = UIFont.boldSystemFont(ofSize: fontSize)
//
//        var textParts: [Text] = []
//
//        for part in parts {
//            switch part {
//                case .user_mention(let string):
//                    if let user = viewState.users[string] {
//                        let member = viewState.currentSelection.id.flatMap { viewState.members[$0] }.flatMap { $0[string] }
//
//                        let name = member?.nickname ?? user.display_name ?? user.username
//
//                        let mention = NSAttributedString(string: name, attributes: [.foregroundColor: viewState.theme.accent.color, .font: boldFont, .link: "revoltchat://users?user=\(string)"])
//                        let pfpUrl = (member?.avatar ?? user.avatar).map { viewState.formatUrl(with: $0) } ?? "\(viewState.http.baseURL)/users/\(user.id)/default_avatar"
//                        
//                        let image = getImage(url: URL(string: pfpUrl)!, round: true)
//                        let text = Text(Image(uiImage: image)) + Text(AttributedString(mention))
//                        
//                        textParts.append(text)
//                    } else {
//                        textParts.append(Text(AttributedString(NSAttributedString(string: "@Unknown", attributes: [.foregroundColor: viewState.theme.accent.color, .font: boldFont]))))
//                    }
//                case .channel_mention(let string):
//                    let mention: NSAttributedString
//
//                    if let channel = viewState.channels[string] {
//                        let name = channel.getName(viewState)
//
//                        mention = NSAttributedString(string: "#\(name)", attributes: [.foregroundColor: viewState.theme.accent.color, .font: boldFont, .link: "revoltchat://channels?channel=\(string)"])
//                    } else {
//                        mention = NSAttributedString(string: "#Unknown", attributes: [.foregroundColor: viewState.theme.accent.color, .font: boldFont])
//                    }
//
//                    textParts.append(Text(AttributedString(mention)))
//
//                case .text(let string):
//                    if string.count > 0 {
//                        let substring = try! NSMutableAttributedString(markdown: string, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))
//
//                        if var attrString = try? AttributedString(markdown: string) {
//                            attrString.mergeAttributes(AttributeContainer([.font: font, .foregroundColor: viewState.theme.foreground.color]))
//                            textParts.append(Text(attrString))
//                        } else {
//                            textParts.append(Text(string))
//                        }
//                    }
//
//                case .custom_emoji(let id):
//                    let url = viewState.formatUrl(fromEmoji: id)
//                    let image = getImage(url: URL(string: url)!)
//                    
//                    textParts.append(Text(Image(uiImage: image)))
//            }
//        }
//
//        if textParts.count > 0 {
//            let first = textParts.removeFirst()
//            return textParts.reduce(first, (+))
//        } else {
//            return nil
//        }
//    }
//    
//    func loadBody() -> Text {
//        if let cached {
//            return cached
//        } else {
//            if !loading {
//                loading = true
//                
//                DispatchQueue.global(qos: .userInteractive).async {
//                    let parts = parseMentions(text: text)
//                    
//                    DispatchQueue.main.async {
//                        cached = buildContent(parts: parts)
//                    }
//                }
//            }
//            
//            return Text(verbatim: text)
//                .font(Font.system(size: fontSize))
//        }
//    }
//    
//    var body: some View {
////        ZStack {
////            cached ?? Text(verbatim: text).font(Font.system(size: fontSize))
////        }.task {
////            let text = text
////            DispatchQueue.global(qos: .userInteractive).async {
////                let parts = parseMentions(text: text)
////                
////                DispatchQueue.main.async {
////                    cached = buildContent(parts: parts)
////                }
////            }
////        }
//        Text((try? AttributedString(markdown: text)) ?? AttributedString(stringLiteral: text))
//            .font(Font.system(size: fontSize))
//    }
//}

//
//class EmojiView: UIView {
//    var imageView: UIImageView!
//    var label: UILabel!
//    
//    init(imageSize: CGSize) {
//        super.init(frame: .zero)
//        self.imageView = UIImageView(frame: .zero)
//        addSubview(imageView)
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        label.frame = self.bounds
//        imageView.frame = self.bounds
//    }
//}
//
//class UserMentionView: UIView {
//    var imageView: UIImageView!
//    var nameView: UILabel!
//    var tapHandler: (() -> Void)!
//    
//    init(tapHandler: @escaping () -> Void) {
//        super.init(frame: .zero)
//        
//        self.imageView = UIImageView()
//        
//        self.imageView.layer.masksToBounds = false
//        self.imageView.layer.borderWidth = 1
//        self.imageView.layer.borderColor = UIColor.clear.cgColor
//        self.imageView.clipsToBounds = true
//        
//        self.nameView = UILabel()
//        self.nameView.numberOfLines = 1
//        
//        self.tapHandler = tapHandler
//        let gestureRecog = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
//
//        addSubview(imageView)
//        addSubview(nameView)
//        
//        imageView.snp.makeConstraints { make in
//            make.width.equalTo(imageView.snp.height)
//            //make.leading.equalTo(self.snp.leading)
//            make.top.equalTo(self.snp.top).offset(2)
//            make.bottom.equalTo(self.snp.bottom).offset(-2)
//            make.trailing.equalTo(nameView.snp.leading).offset(-8)
//        }
//        
//        nameView.snp.makeConstraints { make in
//            //make.trailing.equalTo(self.snp.trailing)
//            make.centerY.equalTo(imageView.snp.centerY)
//        }
//        
//        self.snp.makeConstraints { make in
//            make.leading.equalTo(imageView.snp.leading).offset(-2).priority(.required)
//            make.trailing.equalTo(nameView.snp.trailing).offset(6).priority(.required)
//        }
//    }
//    
//    required init(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    override func layoutSubviews() {
//        imageView.layer.cornerRadius = imageView.frame.height / 2
//    }
//    
//    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
//        self.tapHandler()
//    }
//}
//
//let highlighter = Highlightr()!
//
//
//struct InnerContents: UIViewRepresentable {
//    @EnvironmentObject var viewState: ViewState
//    typealias UIViewType = SubviewAttachingTextView
//    
//    @Binding var text: String
//    @Binding var calculatedHeight: CGFloat
//    
//    var currentServer: String?
//    
//    var fontSize: CGFloat
//    var font: UIFont
//    var foregroundColor: UIColor
//    var lineLimit: Int?
//    
//    func makeUIView(context: Context) -> UIViewType {
//        let textview = SubviewAttachingTextView()
//        textview.isEditable = false
//        
//        if let lineLimit {
//            textview.textContainer.maximumNumberOfLines = lineLimit
//            textview.textContainer.lineBreakMode = .byTruncatingTail
//        }
//        
//        textview.isSelectable = false
//        textview.font = .systemFont(ofSize: fontSize)
//        textview.backgroundColor = nil
//        textview.isScrollEnabled = false
//        textview.textColor = .white
//        textview.translatesAutoresizingMaskIntoConstraints = false
//        textview.textContainer.lineFragmentPadding = 0
//        textview.textContainerInset = .zero
//        textview.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
//        
//        return textview
//    }
//    
//    func updateUIView(_ textview: UIViewType, context: Context) {
//        if !text.isEmpty {
//            var lines: [NSAttributedString] = []
//            
//            for text in text.split(separator: "\n") {
//                
//                let attrString = try! NSMutableAttributedString(markdown: text.data(using: .utf8)!, options: .init(allowsExtendedAttributes: true, interpretedSyntax: .full))
//                
//                attrString.enumerateAttribute(.font, in: NSRange(location: 0, length: attrString.length), options: [], using: { font, range, _ in
//                    let font = font != nil ? (font as! UIFont).withSize(fontSize) : UIFont.systemFont(ofSize: fontSize)
//                    
//                    // Custom emoji support
////                    let customFont = UIFont(name: "Twitter Color Emoji", size: fontSize)!
////                    let descriptor = customFont.fontDescriptor
////                    let fallback = descriptor.addingAttributes([.name: font.fontName])
////                    let repaired = descriptor.addingAttributes([.cascadeList: [fallback]])
////                    let newFont = UIFont(descriptor: repaired, size: 0.0)
//                    
//                    attrString.addAttribute(.font, value: font, range: range)
//                })
//                
//                var foundCodeblockCount = 0
//                
//                attrString.enumerateAttribute(.presentationIntentAttributeName, in: NSRange(location: 0, length: attrString.length), using: { presentation, range, _ in
//                    if let intent = presentation as? __NSPresentationIntent {
//                        
//                        if intent.intentKind == __NSPresentationIntentKind.codeBlock {
//                            let lowerInt = range.lowerBound - foundCodeblockCount
//                            let lower = String.Index(encodedOffset: lowerInt)
//                            let upper = String.Index(encodedOffset: range.upperBound - foundCodeblockCount)
//                            let codeText = String(attrString.string[lower..<upper])
//                            
//                            let globalRange = Range(uncheckedBounds: (lower, upper))
//                            
//                            if let codeblockString = highlighter.highlight(codeText, as: intent.languageHint) {
//                                attrString.deleteCharacters(in: NSRange(globalRange, in: attrString.string))
//                                attrString.insert(codeblockString, at: lowerInt)
//                            }
//                        }
//                    }
//                })
//                
//                attrString.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: attrString.length), options: [], using: { color, range, _ in
//                    attrString.addAttribute(.foregroundColor, value: color ?? foregroundColor, range: range)
//                })
//                //let run = attrString.string[String.Index(utf16Offset: range.location, in: attrString.string)..<String.Index(utf16Offset: range.location + range.length, in: attrString.string)]
//                
//                var foundEmojiCount = 0
//                
//                for match in attrString.string.matches(of: /:(\w{26}):/) {
//                    let id = match.output.1
//                    
//                    let lowerInt = match.range.lowerBound.encodedOffset - (foundEmojiCount * 27)
//                    let lower = String.Index(encodedOffset: lowerInt)
//                    let upper = String.Index(encodedOffset: match.range.upperBound.encodedOffset - (foundEmojiCount * 27))
//                    
//                    let globalRange = Range(uncheckedBounds: (lower, upper))
//                    
//                    attrString.deleteCharacters(in: NSRange(globalRange, in: attrString.string))
//                    
//                    let view = EmojiView(imageSize: CGSize(width: fontSize, height: fontSize))
//                    view.label = UILabel()
//                    view.label.text = "Hello"
//                    textview.addSubview(view)
//                    view.imageView.kf.setImage(with: URL(string: "https://autumn.revolt.chat/emojis/\(id)")!, placeholder: .none)
//                    
//                    attrString.insert(NSAttributedString(attachment: SubviewTextAttachment(view: view, size: CGSize(width: fontSize, height: fontSize))), at: lowerInt)
//                    
//                    foundEmojiCount += 1
//                }
//                
//                var foundChannelLength = 0
//                
//                for match in attrString.string.matches(of: /<#(\w{26})>/) {
//                    let id = match.output.1
//                    
//                    if let channel = viewState.channels[String(id)] {
//                        let lowerInt = match.range.lowerBound.encodedOffset - foundChannelLength
//                        let lower = String.Index(encodedOffset: lowerInt)
//                        let upper = String.Index(encodedOffset: match.range.upperBound.encodedOffset - foundChannelLength)
//                        
//                        let globalRange = Range(uncheckedBounds: (lower, upper))
//                        
//                        var currentAttrs = attrString.attributes(at: lowerInt, effectiveRange: nil)
//                        
//                        currentAttrs[.link] = URL(string: "revoltchat://channels?channel=\(id)")!
//                        currentAttrs[.backgroundColor] = UIColor.clear.withAlphaComponent(0.1)
//                        
//                        let channelName = channel.getName(viewState)
//                        attrString.deleteCharacters(in: NSRange(globalRange, in: attrString.string))
//                        attrString.insert(NSAttributedString(string: "#\(channelName)", attributes: currentAttrs), at: lowerInt)
//                        
//                        foundChannelLength += 28 - channelName.count
//                    }
//                }
//                
//                var foundUserCount = 0
//                
//                for match in attrString.string.matches(of: /<@(\w{26})>/) {
//                    let id = match.output.1
//                    
//                    if let user = viewState.users[String(id)] {
//                        let member = currentServer.flatMap { viewState.members[$0]![user.id] }
//                        
//                        let lowerInt = match.range.lowerBound.encodedOffset - (foundUserCount * 28)
//                        let lower = String.Index(encodedOffset: lowerInt)
//                        let upper = String.Index(encodedOffset: match.range.upperBound.encodedOffset - (foundUserCount * 28))
//                        
//                        let globalRange = Range(uncheckedBounds: (lower, upper))
//                        
//                        let currentAttrs = attrString.attributes(at: lowerInt, effectiveRange: nil)
//                        let currentFont = (currentAttrs[.font] ?? font) as! UIFont
//                        
//                        attrString.deleteCharacters(in: NSRange(globalRange, in: attrString.string))
//                        
//                        let view = UserMentionView() {
//                            viewState.openUserSheet(user: user, member: member)
//                        }
//                        
//                        view.backgroundColor = viewState.theme.background2.uiColor
//                        view.layer.cornerRadius = currentFont.pointSize / 2
//                        
//                        view.imageView.kf.setImage(
//                            with: viewState.resolveAvatarUrl(user: user, member: member, masquerade: nil),
//                            options: [
//                                .processor(ResizingImageProcessor(referenceSize: CGSize(width: currentFont.pointSize, height: currentFont.pointSize), mode: .aspectFill))
//                            ]
//                        )
//                        view.imageView.frame = CGRect(x: 0, y: 0, width: currentFont.pointSize, height: currentFont.pointSize)
//                        
//                        view.nameView.text = member?.nickname ?? user.display_name ?? user.username
//                        view.nameView.font = .boldSystemFont(ofSize: currentFont.pointSize)
//                        
//                        textview.addSubview(view)
//                        
//                        attrString.insert(NSAttributedString(attachment: SubviewTextAttachment(view: view)), at: lowerInt)
//                        
//                        foundUserCount += 1
//                    }
//                }
//                
//                lines.append(attrString)
//            }
//            
//            var attrString = NSMutableAttributedString(attributedString: lines.remove(at: 0))
//            
//            for line in lines {
//                attrString.append(NSAttributedString(string: "\n"))
//                attrString.append(line)
//            }
//            
//            textview.attributedText = attrString
//        } else {
//            textview.attributedText = NSAttributedString()
//        }
//        
//        
//        InnerContents.recalculateHeight(view: textview, result: $calculatedHeight)
//    }
//    
//    static func recalculateHeight(view: UIView, result: Binding<CGFloat>) {
//        let newSize = view.sizeThatFits(CGSize(width: view.frame.width, height: .greatestFiniteMagnitude))
//        
//        guard result.wrappedValue != newSize.height else { return }
//        DispatchQueue.main.async { // call in next render cycle.
//            result.wrappedValue = newSize.height
//        }
//    }
//}

import SwiftUI
import UIKit
import Kingfisher
import SubviewAttachingTextView
import SnapKit
import Highlightr

class EmojiView: UIView {
    var imageView: UIImageView!
    var label: UILabel!
    
    init(imageSize: CGSize) {
        super.init(frame: .zero)
        self.imageView = UIImageView(frame: .zero)
        addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UserMentionView: UIView {
    var imageView: UIImageView!
    var nameView: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        createSubViews(imageHeight: frame.height)
    }
    
    init(imageHeight: CGFloat) {
        super.init(frame: .zero)
        createSubViews(imageHeight: imageHeight)
    }
    
    private func createSubViews(imageHeight: CGFloat) {
        self.imageView = UIImageView()
        
        self.imageView.layer.masksToBounds = false
        self.imageView.layer.borderWidth = 1
        self.imageView.layer.borderColor = UIColor.clear.cgColor
        self.imageView.clipsToBounds = true
        
        self.nameView = UILabel()
        self.nameView.numberOfLines = 1
        
        addSubview(imageView)
        addSubview(nameView)
        
        imageView.snp.makeConstraints { make in
            make.leading.equalTo(self.snp.leading).offset(2).labeled("image leading")
            
            make.height.equalTo(imageHeight).labeled("image height")
            make.width.equalTo(imageView.snp.height).labeled("image width")
            make.centerY.equalTo(self.snp.centerY).labeled("image center y")
        }
        
        nameView.snp.makeConstraints { make in
            make.leading.equalTo(imageView.snp.trailing).offset(4).labeled("name leading")
            
            make.centerY.equalTo(self.snp.centerY).labeled("name center y")
            
            make.trailing.equalTo(self.snp.trailing).offset(-6).labeled("name trailing")
        }
        
        self.snp.makeConstraints{ make in
            make.height.equalTo(nameView.snp.height).labeled("mention height")
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CodeBlockView: UIView {
    var langView: UIView?
    var contentView: UITextView!
    var scrollview: UIScrollView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        createSubViews(attrString: NSAttributedString(string: ""), backgroundColor: .black, lang: nil, langFont: UIFont.systemFont(ofSize: UIFont.systemFontSize))
    }
    
    init(attrString: NSAttributedString, backgroundColor: UIColor, lang: String?, langFont: UIFont) {
        super.init(frame: .zero)
        createSubViews(attrString: attrString, backgroundColor: backgroundColor, lang: lang, langFont: langFont)
    }
    
    private func createSubViews(attrString: NSAttributedString, backgroundColor: UIColor, lang: String?, langFont: UIFont) {
        self.backgroundColor = backgroundColor
        
        if let lang {
            let text = UILabel()
            let langView = UIView()
            
            text.text = lang.uppercased()
            text.font = langFont
            text.textColor = .black
            
            langView.backgroundColor = .systemRed
            langView.layer.cornerRadius = 4
            
            langView.addSubview(text)
            self.langView = langView
            addSubview(langView)
            
            text.snp.makeConstraints { make in
                make.top.equalTo(langView.snp.top).offset(2)
                make.bottom.equalTo(langView.snp.bottom).offset(-2)
                make.leading.equalTo(langView.snp.leading).offset(6)
                make.trailing.equalTo(langView.snp.trailing).offset(-6)
            }
        }
        
        let contentView = UITextView()
        self.contentView = contentView
        
        contentView.isScrollEnabled = false
        contentView.showsHorizontalScrollIndicator = true
        contentView.isUserInteractionEnabled = false
        contentView.isEditable = false
        contentView.attributedText = attrString
        contentView.backgroundColor = backgroundColor
        
        let scrollview = UIScrollView()
        scrollview.showsHorizontalScrollIndicator = true
        scrollview.showsVerticalScrollIndicator = false
        scrollview.isScrollEnabled = true
        
        //        scrollview.addSubview(contentView)
        
        addSubview(contentView)
        
        //        contentView.snp.makeConstraints { make in
        //            make.top.equalToSuperview().offset(30)
        //            make.bottom.equalToSuperview().offset(-30)
        //            make.leading.equalToSuperview().offset(30)
        //            make.trailing.equalToSuperview().offset(-30)
        //            make.top.equalTo(scrollview.snp.top)
        //            make.bottom.equalTo(scrollview.snp.bottom)
        //        }
        
        if let langView {
            langView.snp.makeConstraints { make in
                make.top.equalTo(self.snp.top).offset(12)
                make.leading.equalTo(self.snp.leading).offset(12)
                make.trailing.lessThanOrEqualTo(self.snp.trailing).offset(-6)
            }
        }
        
        contentView.snp.makeConstraints { make in
            if let langView {
                make.top.equalTo(langView.snp.bottom).offset(4)
            } else {
                make.top.equalTo(self.snp.top).offset(4)
            }
            
            make.leading.equalTo(self.snp.leading).offset(8)
            make.trailing.equalTo(self.snp.trailing).offset(-8).priority(.high)
            make.bottom.equalTo(self.snp.bottom).offset(-8)
        }
        
        self.layer.cornerRadius = 8
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

let defaultParagraphStyle: NSParagraphStyle = {
    var paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.paragraphSpacing = 8.0
    paragraphStyle.minimumLineHeight = 20.0
    //paragraphStyle.lineBreakMode = .byTruncatingTail
    return paragraphStyle
}()

class UserMentionTapHandler: NSObject {
    let callback: () -> Void
    
    init(callback: @escaping () -> Void) {
        self.callback = callback
    }
    
    @objc func handle(_: UITapGestureRecognizer) {
        callback()
    }
}

let highlighter = Highlightr()!

struct InnerContents: UIViewRepresentable {
    @EnvironmentObject var viewState: ViewState
    @Environment(\.currentServer) var currentServer: Server?
    
    typealias UIViewType = SubviewAttachingTextView
    
    @Binding var content: String
    
    @State var handlers: [UserMentionTapHandler] = []
        
    var fontSize: CGFloat
    var contentFont: UIFont
    var foregroundColor: UIColor
    var lineLimit: Int
    var textAlignment: TextAlignment
    
    @Binding var calculatedHeight: CGFloat
    
    init(content: Binding<String>, calculatedHeight: Binding<CGFloat>, fontSize: CGFloat? = nil, font: UIFont? = nil, foregroundColor: UIColor? = nil, lineLimit: Int? = nil, textAlignment: TextAlignment) {
        self._content = content
        self.fontSize = fontSize ?? UIFont.systemFontSize
        self.contentFont = .systemFont(ofSize: fontSize ?? UIFont.systemFontSize)
        self.foregroundColor = foregroundColor ?? .white
        self._calculatedHeight = calculatedHeight
        self.lineLimit = lineLimit ?? 0
        self.textAlignment = textAlignment
        
        highlighter.setTheme(to: "atom-one-dark")
        highlighter.theme.setCodeFont(UIFont.monospacedSystemFont(ofSize: self.fontSize * 0.9, weight: .regular))
    }
    
    func makeUIView(context: Context) -> UIViewType {
        let textview = SubviewAttachingTextView()
        textview.isEditable = false

        textview.textContainer.maximumNumberOfLines = lineLimit
        textview.textContainer.lineBreakMode = .byTruncatingTail
        
        switch textAlignment {
            case .leading:
                textview.textAlignment = .natural
            case .center:
                textview.textAlignment = .center
            case .trailing:
                // no trailing in NSTextAlignment so need to manually do left or right on layout direction
                textview.textAlignment = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft ? .left : .right
        }

        textview.isSelectable = false
        textview.font = contentFont
        textview.backgroundColor = nil
        textview.isScrollEnabled = false
        textview.textColor = foregroundColor
        textview.translatesAutoresizingMaskIntoConstraints = false
        textview.textContainer.lineFragmentPadding = 0
        textview.textContainerInset = .zero
        textview.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        return textview
    }
    
    func fixAttributedStringStyling(for string: NSMutableAttributedString) {
        string.addAttribute(.paragraphStyle, value: defaultParagraphStyle, range: NSRange(location: 0, length: string.length))
        
        string.enumerateAttribute(.font, in: NSRange(location: 0, length: string.length), options: [], using: { font, range, _ in
            let font = font != nil ? (font as! UIFont).withSize(fontSize) : UIFont.systemFont(ofSize: fontSize)
            
            string.addAttribute(.font, value: font, range: range)
        })
        
        string.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: string.length), options: [], using: { color, range, _ in
            string.addAttribute(.foregroundColor, value: color ?? foregroundColor, range: range)
        })
        
        //        string.enumerateAttribute(.link, in: NSRange(location: 0, length: string.length), using: { value, range, _ in
        //            if value != nil {
        //                string.addAttribute(.foregroundColor, value: UIColor.link, range: range)
        //            }
        //        })
    }
    
    func updateUIView(_ textview: UIViewType, context: Context) {
        DispatchQueue.main.async {
            handlers.removeAll()
        }
        
        let attrString = try! NSMutableAttributedString(markdown: content.data(using: .utf8)!, options: .init(allowsExtendedAttributes: true, interpretedSyntax: .full, failurePolicy: .returnPartiallyParsedIfPossible))
        
        fixAttributedStringStyling(for: attrString)
        
        var inlinePresentationIntents: [(InlinePresentationIntent, NSRange)] = []
        
        attrString.enumerateAttribute(.inlinePresentationIntent, in: NSRange(location: 0, length: attrString.string.count), using: { value, range, _ in
            if let value = value as? UInt {
                inlinePresentationIntents.append((InlinePresentationIntent(rawValue: value), range))
            }
        })
        
        for (presentation, range) in inlinePresentationIntents {
            print(presentation, attrString.string[Range(range, in: attrString.string)!])
            
            if presentation == .code {
                print(attrString.string[String.Index(utf16Offset: range.lowerBound, in: attrString.string)..<String.Index(utf16Offset: range.upperBound, in: attrString.string)])
                attrString.addAttribute(.backgroundColor, value: UIColor.secondarySystemBackground, range: range)
            }
            
            if presentation.isSuperset(of: [.emphasized, .stronglyEmphasized]) {
                let font = (attrString.attributes(at: range.lowerBound, effectiveRange: nil)[.font] as? UIFont) ?? contentFont
                
                let descriptor = font.fontDescriptor
                    .withSymbolicTraits(UIFontDescriptor.SymbolicTraits([.traitBold, .traitItalic]))!
                
                attrString.addAttribute(.font, value: UIFont(descriptor: descriptor, size: font.pointSize), range: range)
            }
        }
        
        var presentationIntents: [(__NSPresentationIntent, NSRange)] = []
        
        attrString.enumerateAttribute(.presentationIntentAttributeName, in: NSRange(location: 0, length: attrString.string.count), using: { value, range, _ in
            if let presentation = value as? __NSPresentationIntent {
                presentationIntents.append((presentation, range))
            }
        })
        
        for (presentation, range) in presentationIntents.reversed() {
            switch presentation.intentKind {
                case .paragraph:
                    break
                    
                case .header:
                    var fontSize: CGFloat
                    
                    switch presentation.headerLevel {
                        case 1:
                            fontSize = 30
                        case 2:
                            fontSize = 25
                        case 3:
                            fontSize = 20
                        case 4:
                            fontSize = 15
                        case 5:
                            fontSize = 10
                        default:
                            fontSize = 5
                    }
                    
                    attrString.addAttribute(.font, value: self.contentFont.withSize(fontSize), range: range)
                    
                case .codeBlock:
                    let lowerInt = range.lowerBound
                    let lower = String.Index(utf16Offset: lowerInt, in: attrString.string)
                    let upper = String.Index(utf16Offset: range.upperBound, in: attrString.string)
                    
                    var codeText = String(attrString.string[lower..<upper])
                    let globalRange = Range(uncheckedBounds: (lower, upper))
                    
                    codeText.removeLast()
                    
                    if let codeBlockString = highlighter.highlight(codeText, as: presentation.languageHint) {
                        attrString.deleteCharacters(in: NSRange(globalRange, in: attrString.string))
                        
                        let wrapperView = CodeBlockView(attrString: codeBlockString, backgroundColor: .secondarySystemBackground, lang: presentation.languageHint, langFont: UIFont(descriptor: contentFont.fontDescriptor.withSymbolicTraits(.traitBold)!, size: 10))
                        textview.addSubview(wrapperView)
                        
                        attrString.insert(NSAttributedString(attachment: SubviewTextAttachment(view: wrapperView)), at: lowerInt)
                    }
                    
                default:
                    break
            }
            
            if range.lowerBound != 0 {
                attrString.mutableString.insert("\n", at: range.lowerBound)
            }
        }
        
        for match in attrString.string.matches(of: /:(\w{26}):/).reversed() {
            let id = match.output.1
            
            let lowerInt = match.range.lowerBound.utf16Offset(in: attrString.string)
            let lower = match.range.lowerBound
            let upper = match.range.upperBound
            
            let currentAttrs = attrString.attributes(at: lowerInt, effectiveRange: nil)
            let currentFont = (currentAttrs[.font] ?? contentFont) as! UIFont
            
            let globalRange = Range(uncheckedBounds: (lower, upper))
            
            attrString.deleteCharacters(in: NSRange(globalRange, in: attrString.string))
            
            let attachment = NSTextAttachment()
            
            
            KF.url(URL(string: "https://autumn.revolt.chat/emojis/\(id)")!)
                .placeholder(.none)
                .appendProcessor(ResizingImageProcessor(referenceSize: CGSize(width: currentFont.lineHeight, height: currentFont.lineHeight), mode: .aspectFit))
                .set(to: attachment, attributedView: textview)
            
            attrString.insert(NSAttributedString(attachment: attachment), at: lowerInt)
        }
        
        for match in attrString.string.matches(of: /<#(\w{26})>/).reversed() {
            let id = match.output.1
            
            if let channel = viewState.channels[String(id)] {
                
                let lowerInt = match.range.lowerBound.utf16Offset(in: attrString.string)
                let lower = match.range.lowerBound
                let upper = match.range.upperBound

                let globalRange = Range(uncheckedBounds: (lower, upper))
                
                var currentAttrs = attrString.attributes(at: lowerInt, effectiveRange: nil)
                
                currentAttrs[.link] = URL(string: "revoltchat://channels?channel=\(id)")!

                let channelName = channel.getName(viewState)
                attrString.deleteCharacters(in: NSRange(globalRange, in: attrString.string))
                attrString.insert(NSAttributedString(string: "#\(channelName)", attributes: currentAttrs), at: lowerInt)
            }
        }
        
        for match in attrString.string.matches(of: /@(everyone|online)/).reversed() {
            let lowerInt = match.range.lowerBound.utf16Offset(in: attrString.string)
            let lower = match.range.lowerBound
            let upper = match.range.upperBound
            
            let globalRange = Range(uncheckedBounds: (lower, upper))
            
            var currentAttrs = attrString.attributes(at: lowerInt, effectiveRange: nil)
            
            currentAttrs[.foregroundColor] = viewState.theme.accent.uiColor
            
            attrString.deleteCharacters(in: NSRange(globalRange, in: attrString.string))
            attrString.insert(NSAttributedString(string: "@\(match.output.1)", attributes: currentAttrs), at: lowerInt)
        }
        
        for match in attrString.string.matches(of: /<%(\w{26})>/).reversed() {
            let id = match.output.1
            
            if let role = currentServer?.roles?[String(id)] {
                let lowerInt = match.range.lowerBound.utf16Offset(in: attrString.string)
                let lower = match.range.lowerBound
                let upper = match.range.upperBound
                
                let globalRange = Range(uncheckedBounds: (lower, upper))
                
                var currentAttrs = attrString.attributes(at: lowerInt, effectiveRange: nil)
                
                currentAttrs[.foregroundColor] = viewState.theme.accent.uiColor  // TODO: somehow do the role colour - current parser emmits swiftui colours
                
                attrString.deleteCharacters(in: NSRange(globalRange, in: attrString.string))
                attrString.insert(NSAttributedString(string: "@\(role.name)", attributes: currentAttrs), at: lowerInt)
            }
        }
        
        for match in attrString.string.matches(of: /<@(\w{26})>/).reversed() {
            let id = match.output.1
            
            if let user = viewState.users[String(id)] {
                let member = currentServer.flatMap { viewState.members[$0.id]![user.id] }
                
                let lowerInt = match.range.lowerBound.utf16Offset(in: attrString.string)
                let lower = match.range.lowerBound
                let upper = match.range.upperBound
                
                let globalRange = Range(uncheckedBounds: (lower, upper))
                
                let currentAttrs = attrString.attributes(at: lowerInt, effectiveRange: nil)
                let currentFont = (currentAttrs[.font] ?? contentFont) as! UIFont
                
                attrString.deleteCharacters(in: NSRange(globalRange, in: attrString.string))
                
                let view = UserMentionView(imageHeight: currentFont.pointSize)
                view.backgroundColor = viewState.theme.background2.uiColor
                view.layer.cornerRadius = currentFont.pointSize / 2
                  
                view.imageView.kf.setImage(
                    with: viewState.resolveAvatarUrl(user: user, member: member, masquerade: nil),
                    options: [
                        .processor(ResizingImageProcessor(referenceSize: CGSize(width: currentFont.pointSize, height: currentFont.pointSize), mode: .aspectFill)),
                        .processor(RoundCornerImageProcessor(cornerRadius: .greatestFiniteMagnitude))
                    ]
                )
                                
                view.nameView.text = member?.nickname ?? user.display_name ?? user.username
                view.nameView.font = .boldSystemFont(ofSize: currentFont.pointSize)
                
                view.isUserInteractionEnabled = true
                
                let handler = UserMentionTapHandler {
                    viewState.openUserSheet(user: user, member: member)
                }
                
                DispatchQueue.main.async {
                    handlers.append(handler)
                }
                
                let recogniser = UITapGestureRecognizer(target: handler, action: #selector(UserMentionTapHandler.handle(_:)))
                view.addGestureRecognizer(recogniser)

                textview.addSubview(view)
                
                attrString.insert(NSAttributedString(attachment: SubviewTextAttachment(view: view)), at: lowerInt)
            }
        }
        
        for match in attrString.string.matches(of: /(?:https?:\/\/)?revolt\.chat\/server\/(\w{26})\/channel\/(\w{26})\/(\w{26})/).reversed() {
            let serverId = String(match.output.1)
            let channelId = String(match.output.2)
            let messageId = match.output.3
            
            if let server = viewState.servers[serverId],
               let channel = viewState.channels[channelId],
               channel.server == serverId
            {
                let lowerInt = match.range.lowerBound.utf16Offset(in: attrString.string)
                let lower = match.range.lowerBound
                let upper = match.range.upperBound
                
                let globalRange = Range(uncheckedBounds: (lower, upper))
                
                let currentAttrs = attrString.attributes(at: lowerInt, effectiveRange: nil)
                let currentFont = (currentAttrs[.font] ?? contentFont) as! UIFont
                
                attrString.deleteCharacters(in: NSRange(globalRange, in: attrString.string))
                
                let linkString = NSMutableAttributedString(string: "􀆃\(channel.getName(viewState)) ", attributes: [.font: currentFont])
                
                linkString.append(NSAttributedString(string: "􀆊", attributes: [
                    .font: currentFont.withSize(currentFont.pointSize / 2),
                    .baselineOffset: (currentFont.capHeight - (currentFont.capHeight / 2)) / 2
                ]))
                linkString.append(NSAttributedString(string: " 􀌲", attributes: [.font: currentFont]))
                linkString.addAttributes([
                    .link: URL(string: "revoltchat://channels?channel=\(channelId)&message=\(messageId)")!,  // TODO
                    .backgroundColor: UIColor.clear.withAlphaComponent(0.1),
                    .foregroundColor: foregroundColor
                ], range: NSRange(location: 0, length: linkString.length))
                
                attrString.insert(linkString, at: lowerInt)
            }
        }
        
        for match in attrString.string.matches(of: /<t:(\d+):(t|T|D|f|F|R)>/).reversed() {
            let lowerInt = match.range.lowerBound.utf16Offset(in: attrString.string)
            let lower = match.range.lowerBound
            let upper = match.range.upperBound
            
            let globalRange = Range(uncheckedBounds: (lower, upper))
            
            let currentAttrs = attrString.attributes(at: lowerInt, effectiveRange: nil)
            let currentFont = (currentAttrs[.font] ?? contentFont) as! UIFont
            
            attrString.deleteCharacters(in: NSRange(globalRange, in: attrString.string))
            
            let date = Date(timeIntervalSince1970: Double(match.output.1)!)
            
            var content: String = "unknown"
            
            switch match.output.2 {
                case "t":
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    content = formatter.string(from: date)
                case "T":
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm:ss"
                    content = formatter.string(from: date)
                case "D":
                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd MMMM YYYY"
                    content = formatter.string(from: date)
                case "f":
                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd MMMM YYYY HH:mm"
                    content = formatter.string(from: date)
                case "F":
                    let formatter = DateFormatter()
                    formatter.dateFormat = "EEEE, dd MMMM YYYY HH:mm"
                    content = formatter.string(from: date)
                case "R":
                    let formatter = RelativeDateTimeFormatter()
                    formatter.dateTimeStyle = .numeric
                    formatter.formattingContext = .middleOfSentence
                    formatter.unitsStyle = .full
                    content = formatter.localizedString(for: date, relativeTo: Date.now)
                default:
                    fatalError()
            }
            
            let linkString = NSAttributedString(string: content, attributes: [
                .backgroundColor: UIColor.secondarySystemBackground,
                .foregroundColor: foregroundColor,
                .font: currentFont
            ])
            
            attrString.insert(linkString, at: lowerInt)
        }
        
        textview.attributedText = attrString
        
        InnerContents.recalculateHeight(view: textview, result: $calculatedHeight)
    }
    
    static func recalculateHeight(view: UIView, result: Binding<CGFloat>) {
        let newSize = view.sizeThatFits(CGSize(width: view.frame.width, height: .greatestFiniteMagnitude))
        
        guard result.wrappedValue != newSize.height else { return }
        DispatchQueue.main.async { // call in next render cycle.
            result.wrappedValue = newSize.height
        }
    }
}

struct Contents: View {
    @EnvironmentObject var viewState: ViewState
    @Environment(\.lineLimit) var lineLimit: Int?
    @Environment(\.multilineTextAlignment) var textAlignment: TextAlignment
    
    @State var calculatedHeight: CGFloat = 0
    @Binding var text: String
        
    var fontSize: CGFloat
    var font: UIFont
    var foregroundColor: UIColor?
    
    init(text: Binding<String>, fontSize: CGFloat? = nil, font: UIFont? = nil, foregroundColor: UIColor? = nil) {
        self._text = text
        self.fontSize = fontSize ?? font?.pointSize ?? UIFont.systemFontSize
        self.font = font ?? .systemFont(ofSize: fontSize ?? UIFont.systemFontSize)
        self.foregroundColor = foregroundColor
    }
    
    var body: some View {
        let foreground = foregroundColor ?? viewState.theme.foreground.uiColor
        
        if viewState.userSettingsStore.store.experiments.customMarkdown {
            InnerContents(content: $text, calculatedHeight: $calculatedHeight, fontSize: fontSize, font: font, foregroundColor: foreground, lineLimit: lineLimit, textAlignment: textAlignment)
                .frame(height: calculatedHeight)
        } else {
            Text((try? AttributedString(markdown: text.data(using: .utf8)!)) ?? AttributedString(text))
                .font(Font.system(size: fontSize))
                .foregroundStyle(Color(uiColor: foreground))
                .lineLimit(lineLimit)
                .multilineTextAlignment(textAlignment)
        }
    }
}

struct ParserPreview: PreviewProvider {
    //static let viewState = ViewState.preview().applySystemScheme(theme: .light)

    static var previews: some View {
        Text("asd")
//        Contents(text: .constant("hello <@0>, checkout <#0>!"), fontSize: 16)
//            .applyPreviewModifiers(withState: viewState)
    }
}
