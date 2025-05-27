//
//  ChannelIcon.swift
//  Revolt
//
//  Created by Angelo on 18/10/2023.
//

import Foundation
import SwiftUI
import Types

struct ChannelIcon: View {
    @EnvironmentObject var viewState: ViewState
    
    var channel: Channel
    var withUserPresence: Bool = false
    
    var spacing: CGFloat = 12
    var initialSize: (CGFloat, CGFloat) = (16, 16)
    var frameSize: (CGFloat, CGFloat) = (24, 24)
    
    var body: some View {
        HStack(spacing: spacing) {
            switch channel {
                case .text_channel(let c):
                    if let icon = c.icon {
                        LazyImage(source: .file(icon), height: initialSize.0, width: initialSize.0, clipTo: Rectangle())
                            .frame(width: frameSize.0, height: frameSize.1)
                    } else {
                        Image(systemName: c.voice != nil ? "speaker.wave.2" : "number")
                            .resizable()
                            .frame(width: initialSize.0, height: initialSize.1)
                            .frame(width: frameSize.0, height: frameSize.1)
                    }
                    
                    Text(c.name)
                    
                case .voice_channel(let c):
                    if let icon = c.icon {
                        LazyImage(source: .file(icon), height: initialSize.0, width: initialSize.0, clipTo: Rectangle())
                            .frame(width: frameSize.0, height: frameSize.1)
                    } else {
                        Image(systemName: "speaker.wave.2")
                            .symbolRenderingMode(.hierarchical)
                            .resizable()
                            .frame(width: initialSize.0, height: initialSize.1)
                            .frame(width: frameSize.0, height: frameSize.1)
                    }
                    
                    Text(c.name)
                    
                case .group_dm_channel(let c):
                    if let icon = c.icon {
                        LazyImage(source: .file(icon), height: initialSize.0, width: initialSize.0, clipTo: Rectangle())
                            .frame(width: frameSize.0, height: frameSize.1)
                    } else {
                        Image(systemName: "number")
                            .resizable()
                            .frame(width: initialSize.0, height: initialSize.1)
                            .frame(width: frameSize.0, height: frameSize.1)
                    }
                    
                    Text(c.name)
                    
                case .dm_channel(let c):
                    let recipient = viewState.users[c.recipients.first(where: { $0 != viewState.currentUser!.id })!]!
                    
                    Avatar(user: recipient, withPresence: withUserPresence)
                        .frame(width: initialSize.0, height: initialSize.1)
                        .frame(width: frameSize.0, height: frameSize.1)

                    Text(recipient.username)

                case .saved_messages(_):
                    Image(systemName: "note.text")
                        .resizable()
                        .frame(width: initialSize.0, height: initialSize.1)
                        .frame(width: frameSize.0, height: frameSize.1)
                    
                    Text("Saved Messages")
            }
        }
        .lineLimit(1)
    }
}

struct ChannelIcon_Preview: PreviewProvider {
    static var viewState: ViewState = ViewState.preview()
    
    static var previews: some View {
        ChannelIcon(channel: viewState.channels["0"]!)
            .previewLayout(.sizeThatFits)
    }
}

