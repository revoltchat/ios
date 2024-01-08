//
//  ChannelInfo.swift
//  Revolt
//
//  Created by Angelo on 06/12/2023.
//

import Foundation
import SwiftUI

struct ChannelInfo: View {
    @EnvironmentObject var viewState: ViewState
    
    @Binding var channel: Channel
    
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
                Button {
                    
                } label: {
                    HStack {
                        Image(systemName: "person.crop.circle.fill.badge.plus")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)

                        Text("Invite Members")
                    }
                }
                .listRowBackground(viewState.theme.background2.color)
                
                let users = getUsers()
                
                Section("Members - \(users.count)") {
                    ForEach(users, id: \.0.id) { (user, member) in
                        HStack {
                            Avatar(user: user, member: member, withPresence: true)
                            
                            VStack(alignment: .leading) {
                                Text(verbatim: member?.nickname ?? user.display_name ?? user.username)
                                
                                if let statusText = user.status?.text {
                                    Text(verbatim: statusText)
                                        .font(.footnote)
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
    }
}


#Preview {
    let viewState = ViewState.preview()

    return ChannelInfo(channel: .constant(viewState.channels["0"]!))
        .applyPreviewModifiers(withState: viewState)
}
