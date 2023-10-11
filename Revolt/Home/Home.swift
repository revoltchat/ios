import SwiftUI
import OrderedCollections

class ChannelViewModel: ObservableObject {
    @Published var channel: TextChannel
    @Published var messages: [Message]
    @Published var replies: [Reply] = []

    init(channel: TextChannel, messages: [Message], replies: [Reply] = []) {
        self.channel = channel
        self.messages = messages
        self.replies = replies
    }
}

struct ChannelView: View {
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

            MessageBox(viewModel:MessageBoxViewModel(channel: viewModel.channel, replies: viewModel.replies))
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
                    List(selectedServer.channels, id: \.self, selection: $viewState.currentChannel) { channel in
                        NavigationLink(value: channel) {
                            Text(viewState.channels[channel]!.name)
                        }
                    }
                }
                
            } else {
                Text("Select a server")
            }
        } detail: {
            if let selectedChannel = viewState.currentChannel {
                let channel = viewState.channels[selectedChannel]!
                
                if channel is TextChannel {
                    let messages = viewState.messages[selectedChannel]!
                    
                    ChannelView(viewModel: ChannelViewModel(channel: channel as! TextChannel, messages: messages))
                }
            } else {
                Text("Select a channel")
            }
        }
        .task {
            print(1)
            await viewState.backgroundWsTask()
        }
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home().environmentObject(ViewState())
    }
}
