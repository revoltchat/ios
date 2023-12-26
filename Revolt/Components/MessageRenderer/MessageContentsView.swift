//
//  MessageContentsView.swift
//  Revolt
//
//  Created by Angelo on 12/12/2023.
//

import Foundation
import SwiftUI

class MessageContentsViewModel: ObservableObject {
    var viewState: ViewState

    @Binding var message: Message
    @Binding var author: User
    @Binding var member: Member?
    @Binding var server: Server?
    @Binding var channel: Channel
    @Binding var channelReplies: [Reply]
    @Binding var channelScrollPosition: String?

    init(viewState: ViewState, message: Binding<Message>, author: Binding<User>, member: Binding<Member?>, server: Binding<Server?>, channel: Binding<Channel>, replies: Binding<[Reply]>, channelScrollPosition: Binding<String?>) {
        self.viewState = viewState
        self._message = message
        self._author = author
        self._member = member
        self._server = server
        self._channel = channel
        self._channelReplies = replies
        self._channelScrollPosition = channelScrollPosition
    }
    
    func delete() async {
        await viewState.http.deleteMessage(channel: channel.id, message: message.id)
    }
    
    func report() async {
        
    }
    
    func reply() {
        if !channelReplies.contains(where: { $0.message.id == message.id }) && channelReplies.count < 5 {
            channelReplies.append(Reply(message: message))
        }
    }
}

struct MessageContentsView: View {
    @EnvironmentObject var viewState: ViewState
    @ObservedObject var viewModel: MessageContentsViewModel
    
    @State var showMemberSheet: Bool = false
    @State var showReportSheet: Bool = false
    @State var isStatic: Bool
    
    func copyText() {
#if os(macOS)
        NSPasteboard.general.setString(message.content ?? "", forType: .string)
#else
        UIPasteboard.general.string = viewModel.message.content
#endif
    }
    
    private var isModeratorInChannel: Bool {
        return false // TODO: need bit op stuff
    }
    
    private var isMessageAuthor: Bool {
        viewModel.message.author == viewState.currentUser?.id
    }
    
    private var canDeleteMessage: Bool {
        return isMessageAuthor || isModeratorInChannel
    }
    
    var body: some View {
        let message = viewModel.message
        
        VStack(alignment: .leading) {
            if let content = message.content {
                Contents(text: content)
                    .font(.system(size: 16))
            }
            
            VStack(alignment: .leading) {
                ForEach(message.attachments ?? []) { attachment in
                    MessageAttachment(attachment: attachment)
                }
            }
            
            MessageReactions(reactions: viewModel.$message.reactions, interactions: viewModel.$message.interactions)
        }
        .sheet(isPresented: $showReportSheet) {
            ReportMessageSheetView(showSheet: $showReportSheet, messageView: viewModel)
        }
        .contextMenu(self.isStatic ? nil : ContextMenu {
            Button(action: viewModel.reply, label: {
                Label("Reply", systemImage: "arrowshape.turn.up.left.fill")
            })
            
            Button(action: copyText, label: {
                Label("Copy contents", systemImage: "doc.on.clipboard")
            })
            
            Button(action: { showMemberSheet.toggle() }, label: {
                Label("Open Profile", systemImage: "person.crop.circle")
            })
            
            if isMessageAuthor {
                Button(role: .destructive, action: {
                    Task {
                        
                    }
                }, label: {
                    Label("Edit", systemImage: "pencil")
                })
            }
            
            if canDeleteMessage {
                Button(role: .destructive, action: {
                    Task {
                        await viewModel.delete()
                    }
                }, label: {
                    Label("Delete", systemImage: "trash")
                })
            }
            
            if !isMessageAuthor {
                Button(role: .destructive, action: { showReportSheet.toggle() }, label: {
                    Label("Report", systemImage: "exclamationmark.triangle")
                })
            }
        })
        .swipeActions(edge: .trailing) {
            isStatic ? nil :
            Button(action: viewModel.reply, label: {
                Label("Reply", systemImage: "arrowshape.turn.up.left.fill")
            })
            .tint(.green)
        }
    }
}
