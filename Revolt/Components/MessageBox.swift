//
//  MessageBox.swift
//  Revolt
//
//  Created by Zomatree on 21/04/2023.
//

import Foundation
import SwiftUI

struct Reply {
    var message: Message
    var mention: Bool = false
}

class ReplyViewModel: ObservableObject {
    var idx: Int

    @Binding var replies: [Reply]

    func remove() {
        replies.remove(at: idx)
    }
    
    internal init(idx: Int, replies: Binding<[Reply]>) {
        self.idx = idx
        _replies = replies
    }
}

struct ReplyView: View {
    @EnvironmentObject var viewState: ViewState
    @ObservedObject var viewModel: ReplyViewModel
    
    var id: String
    
    @ViewBuilder
    var body: some View {
        let reply = viewModel.replies[viewModel.idx]
        
        let author = viewState.users[reply.message.author]!

        HStack {
            Button(action: viewModel.remove) {
                Image(systemName: "xmark.circle")
            }
            Avatar(user: author, width:16, height: 16)
            Text(author.username)
            if let content = reply.message.content {
                Text(content)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer()
            Button(action: { viewModel.replies[viewModel.idx].mention.toggle() }) {
                if viewModel.replies[viewModel.idx].mention {
                    Text("@ on")
                        .foregroundColor(.accentColor)
                } else {
                    Text("@ off")
                        .foregroundColor(.black)
                }
            }
        }
    }
}

struct MessageBox: View {
    @EnvironmentObject var viewState: ViewState
    
    @State var showingSelectFile = false
    @State var files: [(URL, String)] = []
    @State var content = ""

    @Binding var channelReplies: [Reply]

    let channel: Channel

    init(channel: Channel, channelReplies: Binding<[Reply]>) {
        self.channel = channel
        _channelReplies = channelReplies
    }
    
    func sendMessage() {
        let c = content
        content = ""
        let f = files
        files = []

        Task {
            await viewState.queueMessage(channel: channel.id, replies: channelReplies, content: c, attachments: f)
        }
    }
    
    func onFileCompletion(res: Result<URL, Error>) {
        if case .success(let url) = res {
            files.append((url, url.lastPathComponent))
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            let typing = Binding($viewState.currentlyTyping[channel.id])

            if let typing = typing {
                var text: [String] = []

                VStack {
                    HStack(spacing: -12) {
                        ForEach(typing, id: \.self) { typing in
                            let user = viewState.users[typing.wrappedValue]!
                            let _ = text.append(user.username)
                            
                            Avatar(user: user, width: 24, height: 24)
                        }
                    }

                    Text(text.joined(separator: ", "))
                }
            }
            ForEach(Array(channelReplies.enumerated()), id: \.element.message.id) { reply in
                let model = ReplyViewModel(idx: reply.offset, replies: $channelReplies)
                ReplyView(viewModel: model, id: reply.element.message.id)
                    .padding(.horizontal, 16)
            }
            ScrollView(.horizontal) {
                HStack {
                    ForEach(Array(files.enumerated()), id: \.element.0.absoluteString) { file in
                        ZStack(alignment: .topTrailing) {
                            LazyImage(source: .url(file.element.0), clipTo: RoundedRectangle(cornerRadius: 5))
                                .frame(height: 100)
                            Button(action: { files.remove(at: file.offset) }) {
                                Image(systemName: "xmark.app.fill")
                                    .resizable()
                                    .foregroundStyle(.gray)
                                    .symbolRenderingMode(.hierarchical)
                                    .opacity(0.9)
                                    .frame(width: 16, height: 16)
                                    .frame(width: 24, height: 24)
                            }
                        }
                    }
                }
            }
            HStack {
                Button(action: { showingSelectFile.toggle() }) {
                    Image(systemName: "plus.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                }
                .fileImporter(isPresented: $showingSelectFile, allowedContentTypes: [.item], onCompletion: onFileCompletion)
            
                ZStack(alignment: .bottomTrailing) {
                    TextField("", text: $content)
                        .placeholder(when: content.isEmpty) {
                            Text("Message \(channel.getName(viewState))")
                        }
                        .foregroundStyle(viewState.theme.textColor.color)
                        .padding([.vertical, .leading, .trailing], 8)
                        .background(RoundedRectangle(cornerRadius: 16)
                            .fill(viewState.theme.messageBox.color)
                            .stroke(viewState.theme.messageBoxBorder.color, lineWidth: 1)
                        )
                    
                    if !content.isEmpty || !files.isEmpty {
                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 28, height: 28)
                                .padding(5)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .background(viewState.theme.messageBoxBackground.color)
    }
}

struct MessageBox_Previews: PreviewProvider {
    static var viewState: ViewState = ViewState.preview()
    @State static var replies: [Reply] = []

    static var previews: some View {
        let channel = viewState.channels["0"]!
        
        MessageBox(channel: channel, channelReplies: $replies)
            .environmentObject(viewState)
            .previewLayout(.sizeThatFits)

    }
}
