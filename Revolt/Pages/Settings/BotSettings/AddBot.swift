//
//  AddBot.swift
//  Revolt
//
//  Created by Angelo on 29/11/2024.
//

import SwiftUI
import Types

enum AddTarget: Identifiable, Hashable, Equatable {
    case server(Server)
    case group(GroupDMChannel)
    
    var id: String {
        switch self {
            case .server(let server):
                return server.id
            case .group(let groupDMChannel):
                return groupDMChannel.id
        }
    }
}

struct AddBot: View {
    @EnvironmentObject var viewState: ViewState
    
    var user: User
    var bot: Bot
    
    @State var targets: [AddTarget] = []
    @State var selected: Set<AddTarget> = []

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Avatar(user: user, width: 64, height: 64)
            
            VStack {
                Text(verbatim: user.display_name ?? user.username)
                    .bold()
                    .font(.title)
                
                Text(verbatim: user.username).bold() + Text("#\(user.discriminator)")
                    .font(.subheadline)
                
            }
            
            if bot.privacy_policy_url != nil || bot.terms_of_service_url != nil {
                HStack {
                    if let url = bot.privacy_policy_url {
                        Text("[Privacy Policy](\(url))")
                    }
                    
                    if bot.privacy_policy_url != nil, bot.terms_of_service_url != nil {
                        Text("•")
                    }
                    
                    if let url = bot.terms_of_service_url {
                        Text("[Terms of Use](\(url))")
                    }
                }
            }
            
            ViewThatFits {
                List(targets, selection: $selected) { target in
                    HStack(spacing: 12) {
                        switch target {
                            case .group(let group):
                                ChannelIcon(channel: .group_dm_channel(group), initialSize: (24, 24), frameSize: (32, 32))
                            case .server(let server):
                                ServerIcon(server: server, height: 32, width: 32, clipTo: Circle())
                                
                                Text(server.name)
                        }
                    }
                    .listRowBackground(viewState.theme.background2)
                }
                .contentMargins(.top, 0, for: .scrollContent)
                .scrollContentBackground(.hidden)
            }
        
            VStack {
                Text("Bots are not verified by Revolt.")
                Text("The bot will not be granted any permissions.")
            }
            .font(.footnote)
            
            Button {
                
            } label: {
                Text("Add Bot")
                    .foregroundStyle(selected.isEmpty ? viewState.theme.foreground2 : viewState.theme.foreground)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
            }
            .disabled(selected.isEmpty)
            .background(viewState.theme.background2)
            .clipShape(.capsule)
            .padding(.leading, 8)
        }
        .onAppear {
            for server in viewState.servers.values {
                targets.append(.server(server))
            }
            
            for channel in viewState.channels.values {
                if case .group_dm_channel(let group) = channel {
                    targets.append(.group(group))
                }
            }
        }
        .background(viewState.theme.background)
        .navigationTitle("Add bot")
        .toolbarBackground(viewState.theme.topBar, for: .automatic)
        .environment(\.editMode, .constant(.active))
    }
}
