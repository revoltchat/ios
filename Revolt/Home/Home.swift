import SwiftUI
import OrderedCollections

class ChannelViewModel: ObservableObject {
    @Published var channel: TextChannel
    @Published var messages: [Message]
    @Published var replies: [Reply] = []
    @Published var queuedMessages: [QueuedMessage] = []

    init(channel: TextChannel, messages: [Message], replies: [Reply] = [], queuedMessages: [QueuedMessage]) {
        self.channel = channel
        self.messages = messages
        self.replies = replies
        self.queuedMessages = []
    }
}

struct TextChannelView: View {
    @ObservedObject var viewModel: ChannelViewModel
    @EnvironmentObject var viewState: ViewState
    @State var showSheet = false
    
    func viewMembers() {
        
    }
    
    func createInvite() {
        
    }
    
    func manageNotifs() {
        
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            List(viewModel.messages, id: \.id) { message in
                let author = viewState.users[message.author]!
                MessageView(viewModel: MessageViewModel(message: message, author: author), channelReplies: $viewModel.replies)
            }
            .backgroundStyle(.white)
            .listStyle(.plain)

//            List(viewModel.queuedMessages, id: \.nonce) { message in
//                GhostMessageView(message: message)
//            }
//                .backgroundStyle(.white)
//                .listStyle(.plain)
            
            MessageBox(viewModel: MessageBoxViewModel(viewState: viewState, channel: viewModel.channel, replies: viewModel.replies))
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
                    Text(server.value.name)
                }
            }
        } content: {
            if let selectedServerId = viewState.currentServer {
                let selectedServer = viewState.servers[selectedServerId]!

                VStack {
                    Text(selectedServer.name)
                    List(selectedServer.channels, id: \.self, selection: $viewState.currentChannel) { channel_id in
                        NavigationLink(value: channel_id) {
                            let channel = viewState.channels[channel_id]

                            switch channel {
                                case .text_channel(let c):
                                    Text(c.name)
                                case .voice_channel(let c):
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
                        let messages = viewState.messages[selectedChannel]!

                        TextChannelView(viewModel: ChannelViewModel(channel: c, messages: messages, queuedMessages: viewState.queuedMessages[selectedChannel] ?? []))
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
