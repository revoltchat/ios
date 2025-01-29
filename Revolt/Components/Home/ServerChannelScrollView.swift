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
    
    @State var updateVoiceState: Bool = false
    
    var toggleSidebar: () -> ()
    
    @State var inviteSheetUrl: InviteUrl? = nil
    
    func getValues() -> (Bool, UnreadCount?, ThemeColor, ThemeColor) {
        let isSelected = viewState.currentChannel.id == channel.id
        let unread = viewState.getUnreadCountFor(channel: channel)
        
        let notificationValue = viewState.userSettingsStore.cache.notificationSettings.channel[channel.id]
        let isMuted = notificationValue == .muted || notificationValue == NotificationState.none
        
        let foregroundColor: ThemeColor
        
        if isSelected {
            foregroundColor = viewState.theme.foreground
        } else if isMuted {
            foregroundColor = viewState.theme.foreground3
        } else if unread != nil {
            foregroundColor = viewState.theme.foreground
        } else {
            foregroundColor = viewState.theme.foreground3
        }
        
        let backgroundColor = isSelected ? viewState.theme.background : viewState.theme.background2
                
        return (isMuted, unread, backgroundColor, foregroundColor)
    }
    
    var body: some View {
        let (isMuted, unread, backgroundColor, foregroundColor) = getValues()
        
        Button {
            toggleSidebar()
            
            viewState.selectChannel(inServer: server.id, withId: channel.id)
        } label: {
            VStack(alignment: .leading) {
                HStack {
                    ChannelIcon(channel: channel)
                        .fontWeight(.medium)
                        .opacity(isMuted ? 0.4 : 1)
                    
                    Spacer()
                    
                    if let unread = unread, !isMuted {
                        UnreadCounter(unread: unread)
                            .padding(.trailing)
                    }
                }
                
                if let channelVoiceState = viewState.voiceStates[channel.id] {
                    ForEach(channelVoiceState.values.compactMap({ participant in
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
                                
                                if !(member.can_receive ?? true) {
                                    Image(systemName: "mic.slash.fill")
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                        .foregroundStyle(.red)
                                } else if !participant.is_publishing {
                                    Image(systemName: "mic.slash.fill")
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                }
                                
                                if !(member.can_receive ?? true) {
                                    Image("headphones.slash")
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                        .foregroundStyle(.red)
                                } else if !participant.is_receiving {
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
        .contextMenu {
            Button("Mark as read") {
                Task {
                    if let last_message = viewState.channelMessages[channel.id]?.last {
                        let _ = try! await viewState.http.ackMessage(channel: channel.id, message: last_message).get()
                    }
                }
            }
            
            Button("Notification options") {
                viewState.path.append(NavigationDestination.channel_info(channel.id))
            }
            
            Button("Create Invite") {
                Task {
                    let res = await viewState.http.createInvite(channel: channel.id)
                    
                    if case .success(let invite) = res {
                        inviteSheetUrl = InviteUrl(url: URL(string: "https://rvlt.gg/\(invite.id)")!)
                    }
                }
            }
        }
        .background(backgroundColor)
        .foregroundStyle(foregroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .sheet(item: $inviteSheetUrl) { url in
            ShareInviteSheet(channel: channel, url: url.url)
        }
    }
}

struct CategoryListItem: View {
    @EnvironmentObject var viewState: ViewState
    
    var server: Server
    var category: Types.Category
    var selectedChannel: String?
    
    var toggleSidebar: () -> ()

    var body: some View {
        let isClosed = viewState.userSettingsStore.store.closedCategories[server.id]?.contains(category.id) ?? false
        
        VStack(alignment: .leading) {
            Button {
                withAnimation(.easeInOut) {
                    if isClosed {
                        viewState.userSettingsStore.store.closedCategories[server.id]?.remove(category.id)
                    } else {
                        viewState.userSettingsStore.store.closedCategories[server.id, default: Set()].insert(category.id)
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "chevron.right")
                        .resizable()
                        .rotationEffect(Angle(degrees: isClosed ? 0 : 90))
                        .scaledToFit()
                        .frame(width: 8, height: 8)
                    
                    Text(category.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(viewState.theme.foreground)
                    
                    Spacer()
                }
                .padding(8)
            }
            
            if !isClosed {
                ForEach(category.channels.compactMap({ viewState.channels[$0] }), id: \.id) { channel in
                    ChannelListItem(server: server, channel: channel, toggleSidebar: toggleSidebar)
                }
            }
        }
    }
}

struct ServerChannelScrollView: View {
    @EnvironmentObject var viewState: ViewState
    @Binding var currentSelection: MainSelection
    @Binding var currentChannel: ChannelSelection
    var toggleSidebar: () -> ()
    
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
                            ServerBadges(value: server.flags)
                            
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
                .padding(.bottom, 10)

                                
                ForEach(nonCategoryChannels.compactMap({ viewState.channels[$0] })) { channel in
                    ChannelListItem(server: server, channel: channel, toggleSidebar: toggleSidebar)
                }
                
                ForEach(server.categories ?? []) { category in
                    CategoryListItem(server: server, category: category, toggleSidebar: toggleSidebar)
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
    return ServerChannelScrollView(currentSelection: .constant(MainSelection.server("0")), currentChannel: .constant(ChannelSelection.channel("2")), toggleSidebar: {})
        .applyPreviewModifiers(withState: state)
}
