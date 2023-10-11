//
//  Message.swift
//  Revolt
//
//  Created by Zomatree on 21/04/2023.
//

import Foundation
import SwiftUI

class MessageViewModel: ObservableObject {
    @Published var message: Message
    @Published var author: User
    @EnvironmentObject var viewState: ViewState

    init(message: Message, author: User) {
        self.message = message
        self.author = author
    }
    
    func delete() async {
        viewState.messages[message.channel]?.removeAll(where: {$0.id == message.id})
    }

    func report() async {
        
    }
}

struct MessageView: View {
    @ObservedObject var viewModel: MessageViewModel
    @Binding var channelReplies: [Reply]

    func reply() {
        if !channelReplies.contains(where: { $0.message.id == viewModel.message.id }) && channelReplies.count < 5 {
            channelReplies.append(Reply(message: viewModel.message))
        }
    }

    var body: some View {
        HStack(alignment: .top) {
            AsyncImage(url: URL(string: viewModel.author.avatar)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .clipShape(Circle())
                        .frame(width: 35, height: 35)
                } else {
                    Color.yellow
                        .clipShape(Circle())
                        .frame(width: 35, height: 35)
                }
            }
            VStack(alignment: .leading) {
                HStack {
                    Text(viewModel.author.username)
                        .fontWeight(.heavy)
                    Text(viewModel.message.createdAt.formatted())
                }
                Text(viewModel.message.content)
                //.frame(maxWidth: .infinity, alignment: .leading)
            }
            //.frame(maxWidth: .infinity, alignment: .leading)
        }
        .listRowSeparator(.hidden)
        .contextMenu {
            Button(action: reply, label: {
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
            Button(action: reply, label: {
                Label("Reply", systemImage: "arrowshape.turn.up.left.fill")
            })
            .tint(.green)
        }
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        Home().environmentObject(ViewState())
    }
}
