//
//  ServerBanSettings.swift
//  Revolt
//
//  Created by Angelo on 02/10/2024.
//

import Foundation
import SwiftUI
import Types

struct ServerBanSettings: View {
    @EnvironmentObject var viewState: ViewState
    
    @Binding var server: Server
    
    @State var bannedUsers: [String: User] = [:]
    @State var bans: [Ban] = []
    
    @State var searchbar: String = ""
    
    var body: some View {
        List {
            Section("Bans - \(bans.count)") {
                ForEach(bans
                    .compactMap { ban in bannedUsers[ban.id.user].map { ($0, ban) } }
                    .filter { (user, ban) in searchbar.isEmpty ? true : user.username.contains(searchbar) },
                        id: \.0
                ) { (user, ban) in
                    
                    HStack {
                        Avatar(user: user)
                            .frame(width: 32, height: 32)
                        
                        Text(verbatim: user.username)
                        + Text("#\(user.discriminator)")
                            .foregroundStyle(viewState.theme.foreground2)
                        
                        Spacer()
                        
                        if let reason = ban.reason {
                            Text(reason)
                        } else {
                            Text("No ban reason.")
                        }
                    }
                    .listRowBackground(viewState.theme.background2)
                    .swipeActions {
                        Button(role: .destructive) {
                            
                        } label: {
                            Label("Revoke", systemImage: "trash.fill")
                        }
                    }
                }
            }
        }
        .searchable(text: $searchbar)
        .scrollContentBackground(.hidden)
        .background(viewState.theme.background)
        .navigationTitle("Bans")
        .toolbarBackground(viewState.theme.topBar.color, for: .automatic)
        .task {
            let banInfo = try! await viewState.http.fetchBans(server: server.id).get()
            for user in banInfo.users {
                bannedUsers[user.id] = user
            }
            
            bans = banInfo.bans
        
        }
    }
}
