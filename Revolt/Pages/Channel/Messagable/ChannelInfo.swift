//
//  ChannelInfo.swift
//  Revolt
//
//  Created by Angelo on 06/12/2023.
//

import Foundation
import SwiftUI
import Types

struct InviteUrl: Identifiable {
    var url: URL
    var id: String {
        url.path()
    }
}

struct UserDisplay: View {
    @EnvironmentObject var viewState: ViewState
    
    var server: Server?
    var user: User
    var member: Member?
    
    var body: some View {
        Button {
            viewState.openUserSheet(user: user, member: member)
        } label: {
            HStack(spacing: 12) {
                Avatar(user: user, member: member, withPresence: true)
                
                VStack(alignment: .leading) {
                    Text(verbatim: member?.nickname ?? user.display_name ?? user.username)
                        .fontWeight(.bold)
                        .foregroundStyle(member?.displayColour(theme: viewState.theme, server: server!) ?? AnyShapeStyle(viewState.theme.foreground.color))
                    
                    if let statusText = user.status?.text {
                        Text(verbatim: statusText)
                            .font(.caption)
                            .foregroundStyle(viewState.theme.foreground2.color)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    } else {
                        switch user.status?.presence {
                            case .Busy:
                                Text("Busy")
                                    .font(.caption)
                                    .foregroundStyle(viewState.theme.foreground2.color)
                                
                            case .Idle:
                                Text("Idle")
                                    .font(.caption)
                                    .foregroundStyle(viewState.theme.foreground2.color)
                                
                            case .Invisible:
                                Text("Invisible")
                                    .font(.caption)
                                    .foregroundStyle(viewState.theme.foreground2.color)
                                
                            case .Online:
                                Text("Online")
                                    .font(.caption)
                                    .foregroundStyle(viewState.theme.foreground2.color)
                                
                            case .Focus:
                                Text("Focus")
                                    .font(.caption)
                                    .foregroundStyle(viewState.theme.foreground2.color)
                                
                            case nil:
                                Text("Offline")
                                    .font(.caption)
                                    .foregroundStyle(viewState.theme.foreground2.color)
                        }
                    }
                }
            }
        }
    }
}

struct ChannelInfo: View {
    @EnvironmentObject var viewState: ViewState
    
    @Binding var channel: Channel
    @State var showInviteSheet: InviteUrl? = nil
    
    func getRoleSectionHeaders() -> [(String, Role)] {
        switch channel {
            case .text_channel, .voice_channel:
                let server = viewState.servers[channel.server!]!
                
                return (server.roles ?? [:])
                    .filter { $0.value.hoist ?? false }
                    .sorted(by: { (r1, r2) in r1.value.rank < r2.value.rank })

            default:
                return []
        }
    }
    
    func getRoleSectionContents(users: [UserMaybeMember], role: String) -> [UserMaybeMember] {
        var role_members: [UserMaybeMember] = []
        let other_hoisted_roles = getRoleSectionHeaders().filter { $0.0 != role }
        let server = viewState.servers[channel.server!]!
        
        for u in users {
            let sorted_member_roles = u.member!.roles?.sorted(by: { (a, b) in server.roles![a]!.rank < server.roles![b]!.rank }) ?? []
            
            if let current_role_pos = sorted_member_roles.firstIndex(of: role),
               other_hoisted_roles.allSatisfy({ other_role in (sorted_member_roles.firstIndex(of: other_role.0) ?? Int.max ) > current_role_pos })
            {
                role_members.append(u)
            }
        }
        
        return role_members
    }
    
    func getNoRoleSectionContents(users: [UserMaybeMember]) -> [UserMaybeMember] {
        switch channel {
            case .text_channel, .voice_channel:
                var no_role_members: [UserMaybeMember] = []
                let section_headers = getRoleSectionHeaders().map { $0.0 }
                
                for u in users {
                    if (u.member?.roles ?? []).allSatisfy({ !section_headers.contains($0) }) {
                        no_role_members.append(u)
                    }
                }
                
                return no_role_members
                
            default:
                return users
        }

    }
    
    func getUsers() -> [UserMaybeMember] {
        switch channel {
            case .saved_messages(_):
                return [UserMaybeMember(user: viewState.currentUser!)]

            case .dm_channel(let dMChannel):
                return dMChannel.recipients.map { UserMaybeMember(user: viewState.users[$0]!) }
                
            case .group_dm_channel(let groupDMChannel):
                return groupDMChannel.recipients.map { UserMaybeMember(user: viewState.users[$0]!) }

            case .text_channel(_), .voice_channel(_):
                return viewState.members[channel.server!]!.values.compactMap {
                    if let user = viewState.users[$0.id.user], user.status != nil, user.status?.presence != nil, user.status?.presence != .Invisible {
                        return UserMaybeMember(user: user, member: $0)
                    } else {
                        return nil
                    }
                }
        }
    }
    
    var body: some View {
        VStack(alignment: .center) {
            VStack(alignment: .center, spacing: 8) {
                if let description = Binding($channel.description) {
                    Contents(text: description)
                        .font(.footnote)
                        .foregroundStyle(viewState.theme.foreground2.color)
                        .multilineTextAlignment(.center)
                }
                
                HStack {
                    NavigationLink(value: NavigationDestination.channel_search(channel.id)) {
                        VStack(alignment: .center) {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                            
                            Text("Search")
                        }
                    }
                    
                    Spacer()
                    
                    NavigationLink(value: NavigationDestination.channel_pins(channel.id)) {
                        VStack(alignment: .center) {
                            Image(systemName: "pin.circle.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                            
                            Text("Pins")
                        }
                    }

                    
                    Spacer()
                    
                    Button {
                        
                    } label: {
                        VStack(alignment: .center) {
                            Image(systemName: "bell.circle.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                            
                            Text("Mute")
                        }
                    }
                    
                    Spacer()
                    
                    NavigationLink(value: NavigationDestination.channel_settings(channel.id)) {
                        VStack(alignment: .center) {
                            Image(systemName: "gearshape.circle.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                            
                            Text("Settings")
                        }
                    }
                }
                .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 32)
            
            List {
                if case .dm_channel(let dm) = channel {
                    let recipient = dm.recipients.first { $0 != viewState.currentUser!.id }!
                    
                    NavigationLink(value: NavigationDestination.create_group([recipient])) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.message.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                            
                            Text("New Group")
                        }
                    }
                    .listRowBackground(viewState.theme.background2.color)
                    
                } else if case .text_channel = channel {
                    Button {
                        Task {
                            let res = await viewState.http.createInvite(channel: channel.id)
                            
                            if case .success(let invite) = res {
                                showInviteSheet = InviteUrl(url: URL(string: "https://rvlt.gg/\(invite.id)")!)
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.fill.badge.plus")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)
                            
                            Text("Invite Users")
                        }
                    }
                    .listRowBackground(viewState.theme.background2.color)
                }
                
                let users = getUsers()
                let sections = getRoleSectionHeaders()
                
                let server = channel.server.map { viewState.servers[$0]! }
                
                ForEach(sections, id: \.0) { (roleId, role) in
                    let role_users = getRoleSectionContents(users: users, role: roleId)
                    
                    if !role_users.isEmpty {
                        Section("\(role.name) - \(role_users.count)") {
                            ForEach(role_users) { u in
                                UserDisplay(server: server, user: u.user, member: u.member)
                            }
                        }
                        .listRowBackground(viewState.theme.background2)
                    } else {
                        EmptyView()
                    }
                }
                
                let no_role = getNoRoleSectionContents(users: users)
                
                if !no_role.isEmpty {
                    Section("Members - \(no_role.count)") {
                        ForEach(no_role) { u in
                            UserDisplay(server: server, user: u.user, member: u.member)
                        }
                    }
                    .listRowBackground(viewState.theme.background2)
                }
            }
            .scrollContentBackground(.hidden)
            .background(viewState.theme.background.color)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                ChannelIcon(channel: channel)
            }
        }
        .toolbarBackground(viewState.theme.topBar.color, for: .automatic)
        .background(viewState.theme.background.color)
        .sheet(item: $showInviteSheet) { url in
            ShareInviteSheet(channel: channel, url: url.url)
                .presentationBackground(viewState.theme.background)
        }
    }
}


#Preview {
    let viewState = ViewState.preview()

    return ChannelInfo(channel: .constant(viewState.channels["0"]!))
        .applyPreviewModifiers(withState: viewState)
}
