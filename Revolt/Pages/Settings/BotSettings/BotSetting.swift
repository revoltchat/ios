//
//  BotSetting.swift
//  Revolt
//
//  Created by Angelo on 03/10/2024.
//

import Foundation
import SwiftUI
import Types

struct BotSetting: View {
    @EnvironmentObject var viewState: ViewState
    @Environment(\.dismiss) var dismiss
    
    struct Values: Equatable {
        var bot: Bot
        var user: User
    }
        
    @State var initial: Values
    @State var currentValues: Values
    
    @State var showToken: Bool = false
    
    @State var alertPopupText: String? = nil
    @State var showDeleteBotDialog: Bool = false
    @State var showResetBotTokenDialog: Bool = false
    
    func showPopupText(text: String) {
        withAnimation(.snappy) {
            alertPopupText = text
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.snappy) {
                alertPopupText = nil
            }
        }
    }
    
    init(bot: Bot, user: User) {
        let values = Values(bot: bot, user: user)
        
        self.initial = values
        self.currentValues = values
    }
    
    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Avatar(user: initial.user, width: 64, height: 64)
                        .frame(width: 64, height: 64)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text(verbatim: initial.user.display_name ?? initial.user.username)
                            
                            MessageBadge(text: "Bot", color: viewState.theme.accent.color)
                        }
                        .font(.title2)
                        
                        Button {
                            copyText(text: initial.user.id)
                            showPopupText(text: "Copied ID")
                        } label: {
                            Text(verbatim: initial.user.id)
                                .font(.caption)
                                .foregroundStyle(viewState.theme.foreground2)
                        }
                    }
                }
                
                Button("Copy Token") {
                    copyText(text: currentValues.bot.token)
                    showPopupText(text: "Copied token")
                }
                .foregroundStyle(viewState.theme.accent)
                
                Button("Copy Invite Link") {
                    copyUrl(url: URL(string: "\(viewState.apiInfo!.app)/bot/\(initial.user.id)")!)
                    showPopupText(text: "Copied invite link")
                }
                .foregroundStyle(viewState.theme.accent)
                
                NavigationLink {
                    AddBot(user: initial.user, bot: initial.bot)
                } label: {
                    Text("Add Bot")
                        .foregroundStyle(viewState.theme.accent)
                }
                .tint(viewState.theme.accent)
            }
            .listRowBackground(viewState.theme.background2)

                
            Section("Username") {
                TextField("Username", text: $currentValues.user.username)
            }
            .listRowBackground(viewState.theme.background3)
            
            Section {
                CheckboxListItem(title: "Public Bot", isOn: $currentValues.bot.isPublic)
            } footer: {
                Text("Allows others to invite the bot to their servers and groups")
            }
            .listRowBackground(viewState.theme.background2)
            
            Section("Interactions URL") {
                TextField("Interactions url", text: $currentValues.bot.interactions_url.bindOr(defaultTo: ""))
            } footer: {
                Text("Note: this field is reserved for the future.")
            }
            .listRowBackground(viewState.theme.background3)

            Button(role: .destructive) {
                showResetBotTokenDialog.toggle()
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Reset token")
                }
            }
            .foregroundStyle(.red)
            .listRowBackground(viewState.theme.background2)
            
            Button(role: .destructive) {
                showDeleteBotDialog.toggle()
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete bot")
                }
            }
            .foregroundStyle(.red)
            .listRowBackground(viewState.theme.background2)
            
        }
        .confirmationDialog("Are you sure?", isPresented: $showDeleteBotDialog) {
            Button("Delete bot?", role: .destructive) {
                Task {
                    if (try? await viewState.http.deleteBot(id: initial.bot.id).get()) != nil {
                        dismiss()
                    }
                }
            }
        }
        .confirmationDialog("Are you sure?", isPresented: $showResetBotTokenDialog) {
            Button("Reset token?", role: .destructive) {
                Task {
                    if let bot = try? await viewState.http.editBot(id: initial.bot.id, parameters: EditBotPayload(remove: [.token])).get() {
                        currentValues.bot = bot
                        currentValues.user = bot.user!
                        
                        initial = currentValues
                        
                        showPopupText(text: "Bot token reset")
                    }
                }
            }
        }
        .toolbar {
#if os(iOS)
            let placement = ToolbarItemPlacement.topBarTrailing
#elseif os(macOS)
            let placement = ToolbarItemPlacement.automatic
#endif
            ToolbarItem(placement: placement) {
                if initial != currentValues {
                    Button {
                        Task {
                            var payload = EditBotPayload()
                            
                            if initial.user.username != currentValues.user.username {
                                payload.name = currentValues.user.username
                            }
                            
                            if initial.bot.isPublic != currentValues.bot.isPublic {
                                payload.isPublic = currentValues.bot.isPublic
                            }
                            
                            if initial.bot.analytics != currentValues.bot.analytics {
                                payload.analytics = currentValues.bot.analytics
                            }
                            
                            if initial.bot.interactions_url != currentValues.bot.interactions_url {
                                payload.interactions_url = currentValues.bot.interactions_url
                            }
                            
                            if let bot = try? await viewState.http.editBot(id: initial.bot.id, parameters: payload).get() {
                                currentValues.bot = bot
                                currentValues.user = bot.user!
                                
                                initial = currentValues
                            }
                        }
                    } label: {
                        Text("Save")
                            .foregroundStyle(viewState.theme.accent)
                    }
                }
                
            }
        }
        .scrollContentBackground(.hidden)
        .background(viewState.theme.background)
        .navigationTitle(initial.user.username)
        .toolbarBackground(viewState.theme.topBar, for: .automatic)
        .alertPopup(content: alertPopupText)
    }
}
