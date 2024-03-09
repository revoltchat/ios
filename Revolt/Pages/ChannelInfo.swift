//
//  ChannelInfo.swift
//  Revolt
//
//  Created by Angelo on 06/12/2023.
//

import Foundation
import SwiftUI

struct InviteUrl: Identifiable {
    var url: URL
    var id: String {
        url.path()
    }
}

struct ChannelInfo: View {
    @EnvironmentObject var viewState: ViewState
    
    @Binding var channel: Channel
    @State var showInviteSheet: InviteUrl? = nil
    
    func getUsers() -> [(User, Member?)] {
        switch channel {
            case .saved_messages(_):
                return [(viewState.currentUser!, nil)]

            case .dm_channel(let dMChannel):
                return dMChannel.recipients.map { (viewState.users[$0]!, nil) }
                
            case .group_dm_channel(let groupDMChannel):
                return groupDMChannel.recipients.map { (viewState.users[$0]!, nil) }

            case .text_channel(_), .voice_channel(_):
                let members = viewState.members[channel.server!]!
                
                return members.map { (viewState.users[$0]!, $1) }
        }
    }
    
    var body: some View {
        VStack(alignment: .center) {
            VStack {
                if let description = channel.description {
                    Text(verbatim: description)
                        .font(.footnote)
                        .foregroundStyle(viewState.theme.foreground2.color)
                }
                
                HStack {
                    Button {
                        
                    } label: {
                        VStack(alignment: .center) {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                            
                            Text("Search")
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
                
                Section("Members - \(users.count)") {
                    ForEach(users, id: \.0.id) { (user, member) in
                        HStack(spacing: 12) {
                            Avatar(user: user, member: member, withPresence: true)
                            
                            VStack(alignment: .leading) {
                                Text(verbatim: member?.nickname ?? user.display_name ?? user.username)
                                
                                if let statusText = user.status?.text {
                                    Text(verbatim: statusText)
                                        .font(.caption)
                                        .foregroundStyle(viewState.theme.foreground2.color)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                            }
                        }
                    }
                }
                .listRowBackground(viewState.theme.background2.color)
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
        }
    }
}


#Preview {
    let viewState = ViewState.preview()

    return ChannelInfo(channel: .constant(viewState.channels["0"]!))
        .applyPreviewModifiers(withState: viewState)
}
