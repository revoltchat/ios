//
//  EmojiPicker.swift
//  Revolt
//
//  Created by Angelo on 04/02/2024.
//

import Foundation
import SwiftUI
import Flow
import OrderedCollections
import Types

struct EmojiGroup: Decodable {
    var group: String
    var emoji: [PickerEmoji]
}

struct PickerEmoji: Decodable, Identifiable {
    var base: [Int]
    var emojiId: String?  // for custom emojis
    var alternates: [[Int]]
    var emoticons: [String]
    var shortcodes: [String]
    var animated: Bool
    var directional: Bool

    var id: String {
        if let id = emojiId {
            return id
        } else {
            return String(String.UnicodeScalarView(base.compactMap(Unicode.Scalar.init)))
        }
    }
}

enum PickerEmojiParent: Identifiable, Equatable, Hashable {
    static func == (lhs: PickerEmojiParent, rhs: PickerEmojiParent) -> Bool {
        switch (lhs, rhs) {
            case (.server(let s1), .server(let s2)):
                return s1.id == s2.id

            case (.unicode(let s1), .unicode(let s2)):
                return s1 == s2

            default:
                return false
        }
    }

    case server(Server)
    case unicode(String)

    var id: String {
        switch self {
            case .server(let server):
                return server.id
            case .unicode(let name):
                return name
        }
    }

    var name: String {
        switch self {
            case .server(let server):
                return server.name
            case .unicode(let name):
                return name
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
    }
}

struct PickerEmojiCategory {
    var parent: PickerEmojiParent
}

@MainActor
func loadEmojis(withState viewState: ViewState) -> OrderedDictionary<PickerEmojiParent, [PickerEmoji]> {
    let file = Bundle.main.url(forResource: "emoji_15_1_ordering.json", withExtension: nil)!
    let data = try! Data(contentsOf: file)
    
    let baseEmojis = try! JSONDecoder().decode([EmojiGroup].self, from: data)
    
    var emojis: OrderedDictionary<PickerEmojiParent, [PickerEmoji]> = [:]
    
    for emoji in viewState.emojis.values {
        if case .server(let id) = emoji.parent {
            let server = viewState.servers[id.id]!
            let parent = PickerEmojiParent.server(server)
            let emoji = PickerEmoji(
                base: [],
                emojiId: emoji.id,
                alternates: [],
                emoticons: [],
                shortcodes: [],
                animated: emoji.animated ?? false,
                directional: false
            )
            
            if emojis[parent] == nil {
                emojis[parent] = []
            }
            
            emojis[parent]!.append(emoji)
        }
    }
    
    for category in baseEmojis {
        let parent = PickerEmojiParent.unicode(category.group)
        emojis[parent] = category.emoji
    }
    
    return emojis
}

#if os(iOS)
func convertEmojiToImage(text: String) -> UIImage {
    let size = CGSize(width: 32, height: 32)
    UIGraphicsBeginImageContextWithOptions(size, false, 0)
    UIColor.clear.set()
    let rect = CGRect(origin: CGPoint(), size: size)
    UIRectFill(rect)
    (text as NSString).draw(in: rect, withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 30)])
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image!
}
#elseif os(macOS)
func convertEmojiToImage(text: String) -> NSImage {
    let canvas = NSImage(size: NSSize(width: 32, height: 32))
    
    let image = NSImage(size: NSSize(width: 32, height: 32), flipped: false) { rect in
        canvas.draw(in: rect)
        (text as NSString).draw(in: rect, withAttributes: [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 30)])
        return true
    }
    
    return image
}
#endif

struct EmojiPicker: View {
    @EnvironmentObject var viewState: ViewState
    var background: AnyView

    var onClick: (PickerEmoji) -> ()

    @State var scrollPosition: String?

    var body: some View {
        let emojis = loadEmojis(withState: viewState)

        ZStack(alignment: .top) {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(Array(emojis), id: \.0) { (group) in
                        Button {
                            scrollPosition = group.0.id
                        } label: {
                            switch group.0 {
                                case .server(let server):
                                    ServerIcon(server: server, height: 32, width: 32, clipTo: Circle())
                                        .font(.caption)
                                case .unicode(_):
                                    let emojiString = String(String.UnicodeScalarView(group.1.first!.base.compactMap(Unicode.Scalar.init)))

                                    #if os(iOS)
                                    Image(uiImage: convertEmojiToImage(text: emojiString))
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 32, height: 32)

                                    #elseif os(macOS)
                                    Image(nsImage: convertEmojiToImage(text: emojiString))
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 32, height: 32)

                                    #endif
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(4)
            .background(background)
            .zIndex(1)

            List {
                ForEach(Array(emojis), id: \.0) { group in
                    Section(group.0.name) {
                        HFlow {
                            ForEach(group.1) { emoji in
                                HStack {
                                    if let id = emoji.emojiId {
                                        LazyImage(source: .emoji(id), height: 32, width: 32, clipTo: Rectangle())
                                    } else {
                                        //                                        let base = emoji.base.map { String(format: "%02x", $0) }.joined(separator: "")
                                        //                                        let url = "https://raw.githubusercontent.com/jdecked/twemoji/master/assets/72x72/\(base).png"
                                        //
                                        //                                        LazyImage(source: .url(URL(string: url)!), height: 24, width: 24, clipTo: Rectangle())
                                        
                                        let emojiString = String(String.UnicodeScalarView(emoji.base.compactMap(Unicode.Scalar.init)))
                                        let image = convertEmojiToImage(text: emojiString)
                                        
#if os(iOS)
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 32, height: 32)
                                        
#elseif os(macOS)
                                        Image(nsImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 32, height: 32)
#endif
                                    }
                                        
                                }
                                .onTapGesture {
                                    onClick(emoji)
                                }
                            }
                        }
                    }
                    .id(group.0.id)
                    .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                    .listRowBackground(background)
                    .listRowSeparator(.hidden)
                }
            }
            #if os(iOS)
            .listStyle(.grouped)
            #endif
            .scrollPosition(id: $scrollPosition)
            .padding(.top, 30)
            .scrollContentBackground(.hidden)
            .background(background)

        }
    }
}

#Preview {
    @FocusState var focused: Bool
    @State var showingSelectEmoji: Bool = false
    let viewState = ViewState.preview()

    let box = MessageBox(channel: viewState.channels["0"]!, server: viewState.servers["0"], channelReplies: .constant([]), focusState: $focused, showingSelectEmoji: $showingSelectEmoji, editing: .constant(nil))
    box.showingSelectEmoji = true

    return box.applyPreviewModifiers(withState: ViewState.preview().applySystemScheme(theme: .dark))
}
