//
//  ServerChannelScrollView.swift
//  Revolt
//
//  Created by Angelo on 2023-11-25.
//

import SwiftUI


struct ChannelListItem: View {
    @EnvironmentObject var viewState: ViewState
    var channel: Channel
    
    var body: some View {
        Button(action: {
            viewState.currentChannel = .channel(channel.id)
        }) {
            HStack {
                ChannelIcon(channel: channel)
                
                Spacer()
                
                if let unread = viewState.getUnreadCountFor(channel: channel) {
                    UnreadCounter(unread: unread)
                        .padding(.trailing)
                }
            }
        }
        .foregroundStyle(viewState.theme.foreground.color)
    }
}

struct CategoryListItem: View {
    @EnvironmentObject var viewState: ViewState
    var category: Category
    var selectedChannel: String?

    var body: some View {
        VStack(alignment: .leading) {
            Text(category.title)
                .font(.title3)
            ForEach(category.channels.compactMap({ viewState.channels[$0] }), id: \.id) { channel in
                ChannelListItem(channel: channel)
                    .padding(.vertical, 5)
                    .background((selectedChannel == channel.id ? viewState.theme.background : viewState.theme.background2).color)
                    .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)))
            }
        }

    }
}

struct ServerChannelScrollView: View {
    @EnvironmentObject var viewState: ViewState
    @Binding var currentSelection: MainSelection?
    @Binding var currentChannel: ChannelSelection?
    
    var body: some View {
        let maybeSelectedServer: Server? = switch currentSelection {
            case .server(let serverId): viewState.servers[serverId]!
            default: nil
        }

        if maybeSelectedServer != nil {
            let selectedServer = maybeSelectedServer!
            let selectedChannel: String? = switch currentChannel {
            case .channel(let channelId): channelId
            case .server_settings: selectedServer.id
            case nil: nil
            }
            let categoryChannels = selectedServer.categories?.flatMap(\.channels) ?? []
            let nonCategoryChannels = selectedServer.channels.filter({ !categoryChannels.contains($0) })
            VStack {
                HStack {
                    ServerIcon(server: selectedServer, height: 32, width: 32)
                    Text(selectedServer.name)
                }
                ScrollView {
                    if let banner = selectedServer.banner {
                        if nonCategoryChannels.isEmpty {
                            LazyImage(source: .file(banner), height: 100, clipTo: RoundedRectangle(cornerRadius: 10))
                                .listRowBackground(viewState.theme.background.color)
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            
                        } else {
                            LazyImage(source: .file(banner), height: 100, clipTo: UnevenRoundedRectangle(topLeadingRadius: 10, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 10, style: .continuous))
                                .listRowBackground(viewState.theme.background.color)
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        }
                    }
                    
                    ForEach(nonCategoryChannels.compactMap({ viewState.channels[$0] })) { channel in
                        ChannelListItem(channel: channel)
                            .padding(.vertical, 5)
                            .background((selectedChannel == channel.id ? viewState.theme.background2 : viewState.theme.background).color)
                            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)))
                    }
                    
                    ForEach(selectedServer.categories ?? []) { category in
                        VStack {
                            Divider()
                            CategoryListItem(category: category, selectedChannel: selectedChannel)
                            Spacer()
                                .frame(maxHeight: 10)
                        }
                    }
                    
                    Divider()
                    
                    Button(action: {
                        viewState.currentChannel = .server_settings
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "gearshape.fill")
                                .resizable()
                                .frame(width: 16, height: 16)
                                .frame(width: 24, height: 24)
                            
                            Text("Settings")
                            Spacer()
                        }
                    }
                    .foregroundStyle(viewState.theme.foreground.color)
                    .padding(.vertical, 5)
                    .background((selectedChannel == selectedServer.id ? viewState.theme.background : viewState.theme.background2).color)
                    .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)))
                }
            }
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .background(viewState.theme.background2.color)
        } else {
            Text("How did you get here?")
        }
    }
}

#Preview {
    let state = ViewState.preview()
    return ServerChannelScrollView(currentSelection: .constant(MainSelection.server("0")), currentChannel: .constant(ChannelSelection.channel("2")))
        .environmentObject(state)
}
