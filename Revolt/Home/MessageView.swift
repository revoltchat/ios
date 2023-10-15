//
//  Message.swift
//  Revolt
//
//  Created by Zomatree on 21/04/2023.
//

import Foundation
import SwiftUI

class MessageViewModel: ObservableObject {
    @Binding var message: Message
    @Binding var author: User
    @Binding var channelReplies: [Reply]

    var viewState: ViewState

    init(viewState: ViewState, message: Binding<Message>, author: Binding<User>, replies: Binding<[Reply]>) {
        self.viewState = viewState
        self._message = message
        self._author = author
        self._channelReplies = replies
    }
    
    func delete() async {
        await viewState.http.deleteMessage(channel: message.channel, message: message.id)
    }

    func report() async {
        
    }
    
    func reply() {
        if !channelReplies.contains(where: { $0.message.id == message.id }) && channelReplies.count < 5 {
            channelReplies.append(Reply(message: message))
        }
        
        print(channelReplies)
    }
}

struct MessageView: View {
    @ObservedObject var viewModel: MessageViewModel
    @EnvironmentObject var viewState: ViewState

    var body: some View {
        VStack {
            if let replies = viewModel.message.replies {
                VStack {
                    ForEach(replies, id: \.self) { id in
                        Text(id)
                    }
                }
            }
            HStack(alignment: .top) {
                if let file = viewModel.author.avatar {
                    LazyImage(file: file, height: 32, width: 32, clipTo: Circle())
                        .padding(.trailing, 4)
                } else {
                    Color.black
                        .clipShape(Circle())
                        .frame(width: 32, height: 32)
                        .padding(.trailing, 4)
                }
                VStack(alignment: .leading) {
                    HStack {
                        Text(viewModel.author.username)
                            .fontWeight(.heavy)
                        Text(createdAt(id: viewModel.message.id).formatted())
                            .font(.footnote)
                            .foregroundStyle(.gray)
                        
                        if viewModel.message.edited != nil {
                            Text("(edited)")
                                .font(.footnote)
                                .foregroundStyle(.gray)
                        }
                    }
                    Text(viewModel.message.content)
                    //.frame(maxWidth: .infinity, alignment: .leading)
                    Group {
                        VStack(alignment: .leading) {
                            ForEach(viewModel.message.attachments ?? []) { attachment in
                                LazyImage(file: attachment, clipTo: RoundedRectangle(cornerRadius: 5))
                            }
                        }
                    }
                }
                //.frame(maxWidth: .infinity, alignment: .leading)
            }
            .listRowSeparator(.hidden)
        }
        .contextMenu {
            Button(action: viewModel.reply, label: {
                Label("Reply", systemImage: "arrowshape.turn.up.left.fill")
            })
            
            Button(role: .destructive, action: {
                Task {
                    await viewModel.delete()
                }
            }, label: {
                Label("Delete", systemImage: "trash")
            })
            
            Button(role: .destructive, action: {
                Task {
                    await viewModel.delete()
                }
            }, label: {
                Label("Report", systemImage: "exclamationmark.triangle")
            })
        }
        .swipeActions(edge: .trailing) {
            Button(action: viewModel.reply, label: {
                Label("Reply", systemImage: "arrowshape.turn.up.left.fill")
            })
            .tint(.green)
        }
    }
}

struct GhostMessageView: View {
    @EnvironmentObject var viewState: ViewState
    
    var message: QueuedMessage
    
    var body: some View {
        HStack(alignment: .top) {
            Avatar(user: viewState.currentUser!, width: 16, height: 16)
            VStack(alignment: .leading) {
                HStack {
                    Text(viewState.currentUser!.username)
                        .fontWeight(.heavy)
                    Text(createdAt(id: message.nonce).formatted())
                }
                Text(message.content)
                //.frame(maxWidth: .infinity, alignment: .leading)
            }
            //.frame(maxWidth: .infinity, alignment: .leading)
        }
        .listRowSeparator(.hidden)
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        Home().environmentObject(ViewState())
    }
}
