//
//  BotSettings.swift
//  Revolt
//
//  Created by Angelo on 03/10/2024.
//

import Foundation
import SwiftUI
import Types

struct BotSettings: View {
    @EnvironmentObject var viewState: ViewState
    
    @State var bots: [(Bot, User)] = []
    @State var showCreateBotAlert: Bool = false
    
    var body: some View {
        List {
            Section {
                Button {
                    showCreateBotAlert.toggle()
                } label: {
                    Label("Create a bot", systemImage: "plus")
                }
            }
            .listRowBackground(viewState.theme.background2)
            .listSectionSpacing(.zero)
            
            Text("By creating a bot, you are agreeing to the [Acceptable Usage Policy](https://revolt.chat/aup).")
                .listRowBackground(viewState.theme.background)

            
            Section("My Bots") {
                ForEach(bots, id: \.0.id) { (bot, user) in
                    NavigationLink {
                        BotSetting(bot: bot, user: user)
                    } label: {
                        HStack {
                            Avatar(user: user)
                                .frame(width: 32, height: 32)
                            
                            Text(verbatim: user.display_name ?? user.username)
                            
                            MessageBadge(text: "Bot", color: viewState.theme.accent.color)
                            
                            Spacer()
                            
                            Image(systemName: bot.isPublic ? "globe" : "lock.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                        }
                    }
                }
            }
            .listRowBackground(viewState.theme.background2)
        }
        .task {
            if let response = try? await viewState.http.fetchBots().get() {
                bots = response.bots
                    .compactMap { bot in
                        response.users
                            .first(where: { $0.id == bot.id })
                            .map { (bot, $0) }
                    }
            }
        }
        .scrollContentBackground(.hidden)
        .background(viewState.theme.background)
        .navigationTitle("Bots")
        .toolbarBackground(viewState.theme.topBar, for: .automatic)
        .alert("Create Bot", isPresented: $showCreateBotAlert) {
            CreateBotAlert(bots: $bots)
        }
    }
}


struct CreateBotAlert: View {
    @EnvironmentObject var viewState: ViewState
    
    @Binding var bots: [(Bot, User)]
    @State var name: String = ""
    
    var body: some View {
        TextField("Username", text: $name)
        
        Button("Create") {
            Task {
                if let bot = try? await viewState.http.createBot(username: name).get() {
                    bots.append((bot, bot.user!))
                }
            }
        }
        
        Button("Cancel", role: .cancel) {}
    }
}
