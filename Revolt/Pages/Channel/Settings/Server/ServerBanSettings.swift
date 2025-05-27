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
    @State var bans: [Ban]? = nil
    @State var error: String? = nil
    
    @State var searchbar: String = ""
    @State var banPopout: (User, Ban)? = nil
    
    func filterBans(_ bans: [Ban]) -> [(User, Ban)] {
        bans
            .compactMap { ban in bannedUsers[ban.id.user].map { ($0, ban) } }
            .filter { (user, ban) in
                if searchbar.isEmpty {
                    return true
                } else {
                    let lowercased = searchbar.lowercased()
                    
                    return user.username.lowercased().contains(lowercased)
                    || (user.display_name?.lowercased().contains(lowercased) ?? false)
                    || (ban.reason?.lowercased().contains(lowercased) ?? false)
                }
            }
    }
    
    func unbanUser(_ user: User) async {
        do {
            let _ = try await viewState.http.unbanUser(server: server.id, user: user.id).get()
            bans?.removeAll(where: { $0.id.user == user.id })
            bannedUsers.removeValue(forKey: user.id)
        } catch let e {
            error = e.localizedDescription
        }
    }
    
    func fetchBans() async {
        do {
            let banInfo = try await viewState.http.fetchBans(server: server.id).get()
            for user in banInfo.users {
                bannedUsers[user.id] = user
            }
            
            bans = banInfo.bans
        } catch let e {
            error = e.localizedDescription
        }
    }
    
    var body: some View {
        Group {
            if let error {
                Text(verbatim: error)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else if let bans {
                List {
                    let filtered = filterBans(bans)
                    
                    Section("Bans - \(filtered.count)") {
                        ForEach(filtered, id: \.0) { (user, ban) in
                            Button {
                                banPopout = (user, ban)
                            } label: {
                                HStack {
                                    Avatar(user: user)
                                        .frame(width: 32, height: 32)
                                    
                                    Text(verbatim: user.username)
                                    + Text("#\(user.discriminator)")
                                        .foregroundStyle(viewState.theme.foreground2)
                                    
                                    Spacer()
                                    
                                    Text(ban.reason ?? "No ban reason.")
                                        .truncationMode(.tail)
                                }
                                .lineLimit(1)
                            }
                            .listRowBackground(viewState.theme.background2)
                            .swipeActions {
                                Button(role: .destructive) {
                                    Task { await unbanUser(user) }
                                } label: {
                                    Label("Revoke", systemImage: "trash.fill")
                                }
                            }
                        }
                    }
                }
                .searchable(text: $searchbar)
                .scrollContentBackground(.hidden)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .background(viewState.theme.background)
        .navigationTitle("Bans")
        .toolbarBackground(viewState.theme.topBar.color, for: .automatic)
        .alert(banPopout.map { "\($0.0.username)#\($0.0.discriminator)" } ?? "", isPresented: $banPopout.bindOptionalToBool(), presenting: banPopout, actions: { (user, ban) in
            Button("Unban", role: .destructive) {
                Task { await unbanUser(user) }
            }
        }, message: { (user, ban) in
            Text(ban.reason ?? "No ban reason.")
        })
        .task {
            await fetchBans()
        }
        .refreshable {
            await fetchBans()
        }
    }
}
