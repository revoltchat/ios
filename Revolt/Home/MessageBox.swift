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
    @Published var reply: Reply
    
    internal init(reply: Reply) {
        self.reply = reply
    }
}

struct ReplyView: View {
    @EnvironmentObject var viewState: ViewState
    @ObservedObject var viewModel: ReplyViewModel
    @Binding var replies: [Reply]
    var idx: Int

    var body: some View {
        let author = viewState.users[viewModel.reply.message.author]!

        HStack {
            Button(action: { replies.remove(at: idx) }) {
                Image(systemName: "xmark.circle")
            }
            if let file = author.avatar {
                AsyncImage(url: URL(string: viewState.formatUrl(with: file))) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .clipShape(Circle())
                            .frame(width: 16, height: 16)
                    } else {
                        Color.clear
                            .clipShape(Circle())
                            .frame(width: 16, height: 16)
                    }
                }
            } else {
                Color.black
                    .clipShape(Circle())
                    .frame(width: 16, height: 16)
            }
            Text(author.username)
            Text(viewModel.reply.message.content)
            Spacer()
            Button(action: { viewModel.reply.mention.toggle() }) {
                if viewModel.reply.mention {
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

class MessageBoxViewModel: ObservableObject {
    
    @Published var channel: TextChannel
    @Published var replies: [Reply]
    @Published var files: [URL]
    @Published var content: String

    var viewState: ViewState
    
    internal init(viewState: ViewState, channel: TextChannel, replies: [Reply], content: String = "") {
        self.viewState = viewState
        self.channel = channel
        self.replies = replies
        self.content = content
        self.files = []
    }

    func sendMessage() {
        Task {
            await viewState.queueMessage(channel: channel.id, replies: replies, content: content)
        }
    }
}

struct MessageBox: View {
    @ObservedObject var viewModel: MessageBoxViewModel
    @EnvironmentObject var viewState: ViewState
    @State var showingSelectFile = false

    func onFileCompletion(res: Result<URL, Error>) {
        
    }
    
    var body: some View {
        VStack {
            ForEach(Array(viewModel.replies.enumerated()), id: \.element.message.id) { reply in
                ReplyView(viewModel: ReplyViewModel(reply: reply.element), replies: $viewModel.replies, idx: reply.offset)
                    .padding(.horizontal, 16)
            }
            ScrollView(.horizontal) {
                ForEach(Array(viewModel.files.enumerated()), id: \.offset) { file in
                    Button(action: { viewModel.files.remove(at: file.offset) }) {
                        Text(file.element.absoluteString)
                        Image(systemName: "xmark")
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
                .padding(.leading, 16)
            
                ZStack(alignment: .bottomTrailing) {
                    TextField("Message \(viewModel.channel.name)", text: $viewModel.content)
                        .padding([.vertical, .trailing], 8)
                        .padding(.leading, 8)
                        .background(RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(UIColor.separator), lineWidth: 1)
                        )
                    if viewModel.content != "" {
                        Button(action: viewModel.sendMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 28, height: 28)
                                .padding(5)
                        }
                    }
                }

                
            }
            .padding(.trailing, 16)
            .padding(.bottom, 8)
        }
    }
}

struct MessageBox_Previews: PreviewProvider {
    static var previews: some View {
        Home().environmentObject(ViewState())
    }}
