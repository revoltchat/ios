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
    var isSelected: Bool
    
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
            .padding(8)
        }
        .background((isSelected ? viewState.theme.background : viewState.theme.background2).color)
        .foregroundStyle(viewState.theme.foreground.color)
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

struct CategoryListItem: View {
    @EnvironmentObject var viewState: ViewState
    var category: Category
    var selectedChannel: String?

    var body: some View {
        VStack(alignment: .leading) {
            Text(category.title)
                .fontWeight(.medium)
            
            ForEach(category.channels.compactMap({ viewState.channels[$0] }), id: \.id) { channel in
                ChannelListItem(channel: channel, isSelected: selectedChannel == channel.id)
            }
        }
    }
}

struct ServerChannelScrollView: View {
    @EnvironmentObject var viewState: ViewState
    @Binding var currentSelection: MainSelection
    @Binding var currentChannel: ChannelSelection
    
    var body: some View {
        let maybeSelectedServer: Server? = switch currentSelection {
            case .server(let serverId): viewState.servers[serverId]!
            default: nil
        }

        if let selectedServer = maybeSelectedServer {
            let selectedChannel: String? = switch currentChannel {
                case .channel(let channelId): channelId
                default: nil
            }
            
            let categoryChannels = selectedServer.categories?.flatMap(\.channels) ?? []
            let nonCategoryChannels = selectedServer.channels.filter({ !categoryChannels.contains($0) })
            
            ScrollView {
                if let banner = selectedServer.banner {
                    ZStack(alignment: .bottomLeading) {
                        ZStack {
                            LazyImage(source: .file(banner), height: 100, clipTo: UnevenRoundedRectangle(topLeadingRadius: 5, topTrailingRadius: 5))
                            
                            LinearGradient(colors: [.clear, .clear, .clear, viewState.theme.background2.color], startPoint: .top, endPoint: .bottom)
                                .frame(height: 100)
                        }
                        
                        HStack {
                            Text(selectedServer.name)
                            
                            Spacer()
                            
                            NavigationLink(value: NavigationDestination.server_settings(selectedServer.id)) {
                                HStack(spacing: 12) {
                                    Image(systemName: "gearshape.fill")
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                        .frame(width: 24, height: 24)
                                }
                            }
                            .foregroundStyle(viewState.theme.foreground2.color)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                    }
                    .padding(.bottom, 10)

                }
                                
                ForEach(nonCategoryChannels.compactMap({ viewState.channels[$0] })) { channel in
                    ChannelListItem(channel: channel, isSelected: selectedChannel == channel.id)
                }
                
                ForEach(selectedServer.categories ?? []) { category in
                    CategoryListItem(category: category, selectedChannel: selectedChannel)
                }
            }
            .padding(.horizontal, 8)
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
        .applyPreviewModifiers(withState: state)
}
