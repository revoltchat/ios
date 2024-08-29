//
//  MessageEmbed.swift
//  Revolt
//
//  Created by Angelo on 08/07/2024.
//

import SwiftUI
import Types
import AVKit
import WebKit

struct MessageEmbed: View {
    @EnvironmentObject var viewState: ViewState
    @Binding var embed: Embed
    
    func parseEmbedColor(color: String?) -> AnyShapeStyle {
        if let color {
            return parseCSSColor(currentTheme: viewState.theme, input: color)
        } else {
            return AnyShapeStyle(viewState.theme.foreground3)
        }
    }
    
    var isGif: Bool {
        switch embed {
            case .website(let website):
                switch website.special {
                    case .gif:
                        return true
                    default:
                        return false
                }
            default:
                return false
        }
    }
    
    var body: some View {
        switch embed {
            case .image(let image):
                LazyImage(source: .url(URL(string: image.url)!), clipTo: Rectangle())
            case .text(let embed):
                HStack(spacing: 0) {
                    UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 6)
                        .fill(parseEmbedColor(color: embed.colour))
                        .frame(width: 4)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top, spacing: 6) {
                            if let icon_url = embed.icon_url {
                                if let url = URL(string: icon_url) {
                                    LazyImage(source: .url(url), height: 14, width: 14, clipTo: Rectangle())
                                }
                            }
                            
                            if let title = embed.title {
                                Text(verbatim: title)
                                    .font(.footnote)
                                    .foregroundStyle(viewState.theme.foreground2)
                            }
                        }
                        
                        if let description = embed.description {
                            Text(description)
                        }
                        
                        if let media = embed.media {
                            LazyImage(source: .file(media), clipTo: Rectangle())
                        }
                    }
                    .padding(12)
                    .background(viewState.theme.background2)
                    .clipShape(UnevenRoundedRectangle(bottomTrailingRadius: 6, topTrailingRadius: 6))
                }
            case .website(let embed):
                HStack(spacing: 0) {
                    UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 6)
                        .fill(parseEmbedColor(color: embed.colour))
                        .frame(width: 4)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top, spacing: 6) {
                            if let icon_url = embed.icon_url, embed.site_name != nil {
                                if let url = URL(string: icon_url) {
                                    LazyImage(source: .url(url), height: 14, width: 14, clipTo: Rectangle())
                                }
                            }
                            
                            if let site_name = embed.site_name {
                                Text(verbatim: site_name)
                                    .font(.footnote)
                                    .foregroundStyle(viewState.theme.foreground2)
                            }
                        }
                        
                        if let title = embed.title {
                            Text(verbatim: title)
                                .foregroundStyle(viewState.theme.accent)
                                .font(.headline)
                        }
                        
                        if let description = embed.description {
                            Contents(text: .constant(description), fontSize: 13)
                                //.font(.footnote)
                        }
                        
                        if let special = embed.special, special != .none {
                            SpecialEmbed(embed: embed)
                        } else if let video = embed.video {
                            if let url = URL(string: video.url) {
                                VideoPlayer(player: AVPlayer(url: url))
                                    .frame(width: CGFloat(integerLiteral: video.width), height: CGFloat(integerLiteral: video.height))
                            }
                        } else if let image = embed.image {
                            if image.size == JanuaryImage.Size.large {
                                if let url = URL(string: image.url) {
                                    LazyImage(source: .url(url), clipTo: Rectangle())
                                }
                            }
                        }
                        
                        if let image = embed.image, embed.special == nil || embed.special == WebsiteSpecial.none, embed.video == nil {
                            if image.size == JanuaryImage.Size.preview {
                                if let url = URL(string: image.url) {
                                    LazyImage(source: .url(url), clipTo: Rectangle())
                                }
                            }
                        }
                    }
                    .padding(8)
                    .background(viewState.theme.background2)
                    .clipShape(UnevenRoundedRectangle(bottomTrailingRadius: 6, topTrailingRadius: 6))
                }

            case .none:
                EmptyView()
        }
    }
}

#if os(iOS)
fileprivate struct WebView: UIViewRepresentable {
    let url: URL
    let webview: WKWebView
    
    init(url: URL) {
        self.url = url
        self.webview = WKWebView(frame: .zero)
        self.webview.isOpaque = false
        self.webview.backgroundColor = .clear
    }
    
    func makeUIView(context: Context) -> WKWebView {
        return webview
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
#elseif os(macOS)
fileprivate struct WebView: NSViewRepresentable {
    let url: URL
    let webview: WKWebView
    
    init(url: URL) {
        self.url = url
        self.webview = WKWebView(frame: .zero)
    }
    
    func makeNSView(context: Context) -> WKWebView {
        return webview
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
}
#endif

struct SpecialEmbed: View {
    var embed: WebsiteEmbed
    
    var size: CGFloat {
        switch embed.special! {
            case .youtube:
                return CGFloat(embed.video?.width ?? 16)/CGFloat(embed.video?.height ?? 9)
            case .lightspeed:
                return 16/9
            case .twitch:
                return 16/9
            case .spotify(let special):
                switch special.content_type {
                    case "artist", "playlist":
                        return 400/200
                    default:
                        return 400/105
                }
            case .soundcloud:
                return 480/460
            case .bandcamp:
                return CGFloat(embed.video?.width ?? 16)/CGFloat(embed.video?.height ?? 9)
            default:
                return 0
        }
    }
    
    var url: String? {
        switch embed.special! {
            case .youtube(let special):
                let timestamp = special.timestamp != nil ? "&start=\(special.timestamp!)" : ""
                return "https://www.youtube-nocookie.com/embed/\(special.id)?modestbranding=1\(timestamp)"
            case .twitch(let special):
                return "https://player.twitch.tv/?\(special.content_type.rawValue.lowercased())=\(special.id)&autoplay=false"
            case .lightspeed(let special):
                return "https://new.lightspeed.tv/embed/\(special.id)/stream"
            case .spotify(let special):
                return "https://open.spotify.com/embed/\(special.content_type)/\(special.id)"
            case .soundcloud:
                let url = embed.url!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                return "https://w.soundcloud.com/player/?url=\(url)&color=%23FF7F50&auto_play=false&hide_related=false&show_comments=true&show_user=true&show_reposts=false&show_teaser=true&visual=true"
            case .bandcamp(let special):
                return "https://bandcamp.com/EmbeddedPlayer/\(special.content_type.rawValue.lowercased())=\(special.id)/size=large/bgcol=181a1b/linkcol=056cc4/tracklist=false/transparent=true/"
            case .streamable(let special):
                return "https://streamable.com/e/\(special.id)?loop=0"
            default:
                return nil
        }
    }
    
    var body: some View {
        if let string = url, let url = URL(string: string) {
            WebView(url: url)
                .aspectRatio(size, contentMode: .fit)
        }
    }
}
