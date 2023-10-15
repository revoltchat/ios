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
        let author = viewState.users[viewModel.replies[viewModel.idx].message.author]!

        HStack {
            Button(action: viewModel.remove) {
                Image(systemName: "xmark.circle")
            }
            Avatar(user: author, width:16, height: 16)
            Text(author.username)
            Text(viewModel.replies[viewModel.idx].message.content)
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

class MessageBoxViewModel: ObservableObject {
    
    @Published var channel: TextChannel
    @Binding var channelReplies: [Reply]
    @Published var files: [URL]
    @Published var content: String

    var viewState: ViewState
    
    internal init(viewState: ViewState, channel: TextChannel, replies: Binding<[Reply]>, content: String = "") {
        self.viewState = viewState
        self.channel = channel
        self._channelReplies = replies
        self.content = content
        self.files = []
    }

    func sendMessage() {
        Task {
            await viewState.queueMessage(channel: channel.id, replies: channelReplies, content: content)
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
            ForEach(Array(viewModel.channelReplies.enumerated()), id: \.element.message.id) { reply in
                let model = ReplyViewModel(idx: reply.offset, replies: $viewModel.channelReplies)
                ReplyView(viewModel: model, id: reply.element.message.id)
                    .padding(.horizontal, 16)
            }
            ScrollView(.horizontal) {
                ForEach(Array(viewModel.files.enumerated()), id: \.element.absoluteString) { file in
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
                    
                    if !viewModel.content.isEmpty || !viewModel.files.isEmpty {
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
