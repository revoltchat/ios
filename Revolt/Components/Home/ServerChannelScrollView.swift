//
//  ServerChannelScrollView.swift
//  Revolt
//
//  Created by Angelo on 2023-11-25.
//

import SwiftUI
import Types


struct ChannelListItem: View {
    @EnvironmentObject var viewState: ViewState
    var channel: Channel
    var server: Server
    
    @State var updateVoiceState: Bool = false
    
    var body: some View {
        let isSelected = viewState.currentChannel.id == channel.id
        let unread = viewState.getUnreadCountFor(channel: channel)

        let foregroundColor = isSelected || unread != nil ? viewState.theme.foreground : viewState.theme.foreground2
        let backgroundColor = isSelected ? viewState.theme.background : viewState.theme.background2
        
        Button(action: {
            viewState.currentChannel = .channel(channel.id)
        }) {
            VStack(alignment: .leading) {
                HStack {
                    ChannelIcon(channel: channel)
                    
                    Spacer()
                    
                    if let unread = unread {
                        UnreadCounter(unread: unread)
                            .padding(.trailing)
                    }
                }
                
                if let channelVoiceState = viewState.voiceStates[channel.id] {
                    ForEach(channelVoiceState.participants.compactMap({ participant in
                        let user = viewState.users[participant.id]
                        let member = viewState.members[server.id]![participant.id]
                        
                        if let user, let member {
                            return (participant, user, member)
                        } else {
                            Task {
                                if user == nil {
                                    viewState.users[participant.id] = try! await viewState.http.fetchUser(user: participant.id).get()
                                }
                                
                                if member == nil {
                                    viewState.members[server.id]![participant.id] = try! await viewState.http.fetchMember(server: server.id, member: participant.id).get()
                                }
                                
                                updateVoiceState.toggle()
                            }
                            
                            return nil
                        }
                    }), id: \.0.id) { args in
                        let (participant, user, member) = args
                        
                        Button {
                            viewState.openUserSheet(user: user, member: member)
                        } label: {
                            HStack(spacing: 8) {
                                Avatar(user: user, width: 16, height: 16)
                                Text(verbatim: user.display_name ?? user.username)
                                    .font(.caption)
                                
                                Spacer()
                                
                                if participant.camera {
                                    Image(systemName: "camera.fill")
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                }
                                
                                if participant.screensharing {
                                    Image(systemName: "desktopcomputer")
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                }
                                
                                if !member.can_publish {
                                    Image(systemName: "mic.slash.fill")
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                        .foregroundStyle(.red)
                                } else if !participant.can_publish {
                                    Image(systemName: "mic.slash.fill")
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                }
                                
                                if !member.can_receive {
                                    Image("headphones.slash")
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                        .foregroundStyle(.red)
                                } else if !participant.can_receive {
                                    Image("headphones.slash")
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                }
                            }
                        }
                    }
                    .padding(.leading, 32)
                }
            }
            .padding(8)
        }
        .background(backgroundColor)
        .foregroundStyle(foregroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

struct CategoryListItem: View {
    @EnvironmentObject var viewState: ViewState
    var category: Types.Category
    var selectedChannel: String?
    var server: Server

    var body: some View {
        VStack(alignment: .leading) {
            Text(category.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.leading, 4)
            
            ForEach(category.channels.compactMap({ viewState.channels[$0] }), id: \.id) { channel in
                ChannelListItem(channel: channel, server: server)
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
            case .server(let serverId): viewState.servers[serverId]
            default: nil
        }

        if let selectedServer = maybeSelectedServer {
            let categoryChannels = selectedServer.categories?.flatMap(\.channels) ?? []
            let nonCategoryChannels = selectedServer.channels.filter({ !categoryChannels.contains($0) })
            
            ScrollView {
                ZStack(alignment: .bottomLeading) {
                    if let banner = selectedServer.banner {
                        ZStack {
                            LazyImage(source: .file(banner), height: 100, clipTo: UnevenRoundedRectangle(topLeadingRadius: 5, topTrailingRadius: 5))
                            
                            LinearGradient(colors: [.clear, .clear, .clear, viewState.theme.background2.color], startPoint: .top, endPoint: .bottom)
                                .frame(height: 100)
                        }
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

                                
                ForEach(nonCategoryChannels.compactMap({ viewState.channels[$0] })) { channel in
                    ChannelListItem(channel: channel, server: selectedServer)
                }
                
                ForEach(selectedServer.categories ?? []) { category in
                    CategoryListItem(category: category, server: selectedServer)
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
