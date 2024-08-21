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
    var server: Server
    var channel: Channel
    
    var body: some View {
        let isSelected = viewState.currentChannel.id == channel.id
        let unread = viewState.getUnreadCountFor(channel: channel)

        let foregroundColor = isSelected || unread != nil ? viewState.theme.foreground : viewState.theme.foreground2
        let backgroundColor = isSelected ? viewState.theme.background : viewState.theme.background2
        
        Button {
            viewState.currentChannel = .channel(channel.id)
            viewState.userSettingsStore.store.lastOpenChannels[server.id] = channel.id
        } label: {
            HStack {
                ChannelIcon(channel: channel)
                    .fontWeight(.medium)
                
                Spacer()
                
                if let unread = unread {
                    UnreadCounter(unread: unread)
                        .padding(.trailing)
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
    
    var server: Server
    var category: Types.Category
    var selectedChannel: String?

    var body: some View {
        VStack(alignment: .leading) {
            Text(category.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.leading, 4)
            
            ForEach(category.channels.compactMap({ viewState.channels[$0] }), id: \.id) { channel in
                ChannelListItem(server: server, channel: channel)
            }
        }
    }
}

struct ServerChannelScrollView: View {
    @EnvironmentObject var viewState: ViewState
    @Binding var currentSelection: MainSelection
    @Binding var currentChannel: ChannelSelection
    
    @State var showServerSheet: Bool = false
    
    private var canOpenServerSettings: Bool {
        if let user = viewState.currentUser, let member = viewState.openServerMember, let server = viewState.openServer {
            let perms = resolveServerPermissions(user: user, member: member, server: server)
            
            return !perms.intersection([.manageChannel, .manageServer, .managePermissions, .manageRole, .manageCustomisation, .kickMembers, .banMembers, .timeoutMembers, .assignRoles, .manageNickname, .manageMessages, .manageWebhooks, .muteMembers, .deafenMembers, .moveMembers]).isEmpty
        } else {
            return false
        }
    }
    
    var body: some View {
        let maybeSelectedServer: Server? = switch currentSelection {
            case .server(let serverId): viewState.servers[serverId]
            default: nil
        }

        if let server = maybeSelectedServer {
            let categoryChannels = server.categories?.flatMap(\.channels) ?? []
            let nonCategoryChannels = server.channels.filter({ !categoryChannels.contains($0) })
            
            ScrollView {
                Button {
                    showServerSheet = true
                } label: {
                    ZStack(alignment: .bottomLeading) {
                        if let banner = server.banner {
                            LazyImage(source: .file(banner), height: 120, clipTo: RoundedRectangle(cornerRadius: 12))
                        }
                        
                        HStack(alignment: .center, spacing: 8) {
                            if server.flags?.contains(.offical) == true {
                                ZStack(alignment: .center) {
                                    Image(systemName: "seal.fill")
                                        .resizable()
                                        .frame(width: 12, height: 12)
                                        .foregroundStyle(.white)
                                    
                                    Image("monochrome")
                                        .resizable()
                                        .frame(width: 10, height: 10)
                                        .colorInvert()
                                }
                            } else if server.flags?.contains(.verified) == true {
                                Image(systemName: "checkmark.seal.fill")
                                    .resizable()
                                    .foregroundStyle(.black, .white)
                                    .frame(width: 12, height: 12)
                            }
                            
                            Text(server.name)
                                .fontWeight(.medium)
                                .foregroundStyle(server.banner != nil ? .white : viewState.theme.foreground.color)
                            
                            Spacer()
                            
                            if canOpenServerSettings {
                                NavigationLink(value: NavigationDestination.server_settings(server.id)) {
                                    Image(systemName: "gearshape.fill")
                                        .resizable()
                                        .bold()
                                        .frame(width: 18, height: 18)
                                        .foregroundStyle(server.banner != nil ? .white : viewState.theme.foreground.color)
                                }
                            }
                        }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                            .if(server.banner != nil) { $0.background(
                                UnevenRoundedRectangle(bottomLeadingRadius: 12, bottomTrailingRadius: 12)
                                    .foregroundStyle(LinearGradient(colors: [Color(red: 32/255, green: 26/255, blue: 25/255, opacity: 0.5), .clear], startPoint: .bottom, endPoint: .top))
                                )
                            }
                    }
                    .padding(.bottom, 10)
                }
                                
                ForEach(nonCategoryChannels.compactMap({ viewState.channels[$0] })) { channel in
                    ChannelListItem(server: server, channel: channel)
                }
                
                ForEach(server.categories ?? []) { category in
                    CategoryListItem(server: server, category: category)
                }
            }
            .padding(.horizontal, 8)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .background(viewState.theme.background2.color)
            .sheet(isPresented: $showServerSheet) {
                ServerInfoSheet(server: server)
                    .presentationBackground(viewState.theme.background)
            }
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
