import SwiftUI
import OrderedCollections

@MainActor
class ChannelViewModel: ObservableObject {
    var viewState: ViewState
    @Published var channel: TextChannel
    @Binding var messages: [String]
    @Published var replies: [Reply] = []
    @Published var queuedMessages: [QueuedMessage] = []

    init(viewState: ViewState, channel: TextChannel, messages: Binding<[String]>) {
        self.viewState = viewState
        self.channel = channel
        self._messages = messages
        self.replies = []
        self.queuedMessages = []
    }
    
    func loadMoreMessages(before: String? = nil) {
        Task {
            let result = try! await viewState.http.fetchHistory(channel: channel.id, limit: 50, before: before).get()
            
            for user in result.users {
                viewState.users[user.id] = user
            }
            
            for member in result.members {
                viewState.members[member.id.server]![member.id.user] = member
            }
            
            var ids: [String] = []
            
            for message in result.messages {
                viewState.messages[message.id] = message
                ids.append(message.id)
            }
            
            viewState.channelMessages[channel.id] = ids.reversed() + viewState.channelMessages[channel.id]!
        }
    }
    
    func loadMoreMessagesIfNeeded(current: Message?) {
        guard let item = current else {
            loadMoreMessages()
            return
        }

        if messages.first! == item.id {
            loadMoreMessages(before: item.id)
        }
    }
}

struct TextChannelView: View {
    @EnvironmentObject var viewState: ViewState
    @ObservedObject var viewModel: ChannelViewModel

    @State var showSheet = false
    
    func viewMembers() {
        
    }
    
    func createInvite() {
        
    }
    
    func manageNotifs() {
        
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            List {
                Text("Loading more messages...")
                    .onAppear {
                        viewModel.loadMoreMessages(before: viewModel.messages.first)
                    }

                ForEach($viewModel.messages, id: \.self) { messageId in
                    let message = Binding($viewState.messages[messageId.wrappedValue])!
                    let author = Binding($viewState.users[message.author.wrappedValue])!

                    MessageView(viewModel: MessageViewModel(viewState: viewState, message: message, author: author, replies: $viewModel.replies))
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            }
            .padding(.leading, 0)
            .backgroundStyle(.white)
            .listStyle(.plain)

//            List(viewModel.queuedMessages, id: \.nonce) { message in
//                GhostMessageView(message: message)
//            }
//                .backgroundStyle(.white)
//                .listStyle(.plain)
            
            MessageBox(viewModel: MessageBoxViewModel(viewState: viewState, channel: viewModel.channel, replies: $viewModel.replies))
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button(action: { showSheet.toggle() }) {
                    Text("#\(viewModel.channel.name)")
                    Image(systemName: "chevron.right")
                        .frame(height: 4)
                }.foregroundColor(.black)
            }
        }
        .sheet(isPresented: $showSheet) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .frame(width: 40, height: 49)
                        Image(systemName: "number")
                            .colorInvert()
                    }
                        
                    Text(viewModel.channel.name)
                        .font(.title2)
                }
            
                if let description = viewModel.channel.description {
                    Text("Channel description")
                        .font(.caption)
                        .bold()
                    Text(description)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Options")
                        .font(.caption)
                        .bold()
                    
                    Button(action: viewMembers) {
                        Image(systemName: "list.bullet")
                        Text("Members")
                    }
                    
                    Button(action: createInvite) {
                        Image(systemName: "plus")
                        Text("Invite")
                    }
                    
                    Button(action: manageNotifs) {
                        Image(systemName: "bell.fill")
                        Text("Manage notifications")
                    }
                }
            }
            .frame(alignment: .leading)
            .padding(8)
            .presentationDetents([.fraction(0.30)])

        }
        //.navigationTitle("#\(viewModel.channel.name)")
        //.navigationBarTitleDisplayMode(.inline)
    }
}

struct Home: View {
    @EnvironmentObject var viewState: ViewState
    
    var body: some View {
        NavigationSplitView {
            List(Array(viewState.servers), id: \.self.key, selection: $viewState.currentServer) { server in
                NavigationLink(value: server.key) {
                    if let icon = server.value.icon {
                        LazyImage(file: icon, height: 32, width: 32, clipTo: Circle())
                    }

                    Text(server.value.name)
                }
            }
        } content: {
            if let selectedServerId = viewState.currentServer {
                let selectedServer = viewState.servers[selectedServerId]!

                VStack {
//                    HStack {
//                        if let icon = selectedServer.icon {
//                            LazyImage(file: icon, height: 24, width: 24, clipTo: Circle())
//                        }
//                        Text(selectedServer.name)
//                    }

                    List(selectedServer.channels, id: \.self, selection: $viewState.currentChannel) { channel_id in
                        NavigationLink(value: channel_id) {
                            let channel = viewState.channels[channel_id]
                            
                            switch channel {
                                case .text_channel(let c):
                                    if let icon = c.icon {
                                        LazyImage(file: icon, height: 32, width: 32, clipTo: Rectangle())
                                    } else {
                                        Image(systemName: "number.circle")
                                            .resizable()
                                            .frame(width: 32, height: 32)
                                    }

                                    Text(c.name)
                                case .voice_channel(let c):
                                    if let icon = c.icon {
                                        LazyImage(file: icon, height: 32, width: 32, clipTo: Rectangle())
                                    } else {
                                        Image(systemName: "speaker.wave.2.circle")
                                            .resizable()
                                            .frame(width: 32, height: 32)
                                    }

                                    Text(c.name)
                                default:
                                    EmptyView()
                            }
                        }
                    }
                }
                
            } else {
                Text("Select a server")
            }
        } detail: {
            if let selectedChannel = viewState.currentChannel {
                let channel = viewState.channels[selectedChannel]!
                
                switch channel {
                    case .text_channel(let c):
                        let messages = Binding($viewState.channelMessages[c.id])!
                        
                        let channelViewModel = ChannelViewModel(viewState: viewState, channel: c, messages: messages)
                        TextChannelView(viewModel: channelViewModel)


                    default:
                        Text("Not a text channel :(")
                }
            } else {
                Text("Select a channel")
            }
        }
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home().environmentObject(ViewState())
    }
}
