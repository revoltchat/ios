//
//  MessageReactionsSheet.swift
//  Revolt
//
//  Created by Angelo on 11/09/2024.
//

import Foundation
import SwiftUI
import Types

struct MessageReactionsSheet: View {
    @EnvironmentObject var viewState: ViewState
    
    @ObservedObject var viewModel: MessageContentsViewModel
    @State var selection: String
    
    init(viewModel: MessageContentsViewModel) {
        self.viewModel = viewModel
        selection = viewModel.message.reactions!.keys.first!
    }
    
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(Array(viewModel.message.reactions!.keys), id: \.self) { emoji in
                        Button {
                            selection = emoji
                        } label: {
                            HStack(spacing: 8) {
                                if emoji.count == 26 {
                                    LazyImage(source: .emoji(emoji), height: 16, width: 16, clipTo: Rectangle())
                                } else {
                                    Text(verbatim: emoji)
                                        .font(.system(size: 16))
                                }
                                
                                Text(verbatim: String(viewModel.message.reactions![emoji]!.count))
                                
                            }
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 5).foregroundStyle(selection == emoji ? viewState.theme.background3 : viewState.theme.background2))
                    }
                }
                .padding(16)
            }
            
            HStack {
                let users = viewModel.message.reactions![selection]!
                
                List {
                    ForEach(users.compactMap({ viewState.users[$0] }), id: \.self) { user in
                        let member = viewModel.server.flatMap { viewState.members[$0.id]![user.id] }
                        
                        Button {
                            viewState.openUserSheet(user: user, member: member)
                        } label: {
                            HStack(spacing: 8) {
                                Avatar(user: user, member: member)
                                
                                Text(verbatim: member?.nickname ?? user.display_name ?? user.username)
                            }
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(viewState.theme.background)
                }
                
            }
        }
        .padding(.top, 16)
        .presentationDragIndicator(.visible)
        .presentationBackground(viewState.theme.background)
    }
}
