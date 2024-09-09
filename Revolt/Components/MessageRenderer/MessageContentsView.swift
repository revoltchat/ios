//
//  MessageContentsView.swift
//  Revolt
//
//  Created by Angelo on 12/12/2023.
//

import Foundation
import SwiftUI
import Types

class MessageContentsViewModel: ObservableObject, Equatable {
    var viewState: ViewState

    @Binding var message: Message
    @Binding var author: User
    @Binding var member: Member?
    @Binding var server: Server?
    @Binding var channel: Channel
    @Binding var channelReplies: [Reply]
    @Binding var editing: Message?

    var channelScrollPosition: ChannelScrollController

    init(viewState: ViewState, message: Binding<Message>, author: Binding<User>, member: Binding<Member?>, server: Binding<Server?>, channel: Binding<Channel>, replies: Binding<[Reply]>, channelScrollPosition: ChannelScrollController, editing: Binding<Message?>) {
        self.viewState = viewState
        self._message = message
        self._author = author
        self._member = member
        self._server = server
        self._channel = channel
        self._channelReplies = replies
        self.channelScrollPosition = channelScrollPosition
        self._editing = editing
    }

    static func == (lhs: MessageContentsViewModel, rhs: MessageContentsViewModel) -> Bool {
        lhs.message.id == rhs.message.id
    }

    func delete() async {
        await viewState.http.deleteMessage(channel: channel.id, message: message.id)
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
    @State var showReactSheet: Bool = false
    @State var isStatic: Bool

    private var canManageMessages: Bool {
        let member = viewModel.server.flatMap {
            viewState.members[$0.id]?[viewState.currentUser!.id]
        }

        let permissions = resolveChannelPermissions(from: viewState.currentUser!, targettingUser: viewState.currentUser!, targettingMember: member, channel: viewModel.channel, server: viewModel.server)

        return permissions.contains(.manageMessages)
    }

    private var isMessageAuthor: Bool {
        viewModel.message.author == viewState.currentUser?.id
    }

    private var canDeleteMessage: Bool {
        return isMessageAuthor || canManageMessages
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let content = Binding(viewModel.$message.content) {
                Contents(text: content, fontSize: 16)
                    //.font(.body)
            }

            if let embeds = Binding(viewModel.$message.embeds) {
                ForEach(embeds, id: \.wrappedValue) { embed in
                    MessageEmbed(embed: embed)
                }
            }

            VStack(alignment: .leading) {
                ForEach(viewModel.message.attachments ?? []) { attachment in
                    MessageAttachment(attachment: attachment)
                }
            }

            MessageReactions(
                channel: viewModel.channel,
                message: viewModel.message,
                reactions: viewModel.$message.reactions,
                interactions: viewModel.$message.interactions
            )
        }
        .sheet(isPresented: $showReportSheet) {
            ReportMessageSheetView(showSheet: $showReportSheet, messageView: viewModel)
                .presentationBackground(viewState.theme.background)
        }
        .sheet(isPresented: $showReactSheet) {
            EmojiPicker(background: AnyView(viewState.theme.background)) { emoji in
                Task {
                    showReactSheet = false
                    await viewState.http.reactMessage(channel: viewModel.message.channel, message: viewModel.message.id, emoji: emoji.id)
                }
            }
            .padding([.top, .horizontal])
            .background(viewState.theme.background.ignoresSafeArea(.all))
            .presentationDetents([.large])
            .presentationBackground(viewState.theme.background)
        }
        .contextMenu(menuItems: {
            if !isStatic {
                Button(action: viewModel.reply, label: {
                    Label("Reply", systemImage: "arrowshape.turn.up.left.fill")
                })
                
                Button {
                    showReactSheet = true
                } label: {
                    Label("React", systemImage: "face.smiling.inverse")
                }
                
                Button {
                    copyText(text: viewModel.message.content ?? "")
                } label: {
                    Label("Copy text", systemImage: "doc.on.clipboard")
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
                } else {
                    Button {
                        viewModel.editing = viewModel.message
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
                
                Button {
                    if let server = viewModel.server {
                        copyUrl(url: URL(string: "https://revolt.chat/app/server/\(server.id)/channel/\(viewModel.channel.id)/\(viewModel.message.id)")!)
                    } else {
                        copyUrl(url: URL(string: "https://revolt.chat/app/channel/\(viewModel.channel.id)/\(viewModel.message.id)")!)
                        
                    }
                } label: {
                    Label("Copy message link", systemImage: "doc.on.clipboard")
                }
                
                Button {
                    copyText(text: viewModel.message.id)
                } label: {
                    Label("Copy ID", systemImage: "doc.on.clipboard")
                }
            }
        }) {
            MessageView(viewModel: viewModel, isStatic: true)
                .padding(8)
                .environmentObject(viewState)
        }
        .swipeActions(edge: .trailing) {
            isStatic ? nil :
            Button(action: viewModel.reply, label: {
                Label("Reply", systemImage: "arrowshape.turn.up.left.fill")
            })
            .tint(.green)
        }
    }
}
