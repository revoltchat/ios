import SwiftUI
import OrderedCollections

struct ChannelNavigationLink: View {
    var channel: Channel
    
    var body: some View {
        NavigationLink(value: channel.id) {
            ChannelIcon(channel: channel)
        }
    }
}

struct CategorySection: View {
    @EnvironmentObject var viewState: ViewState
    var category: Category

    var body: some View {
        Section(header: Text(category.title)) {
            ForEach(category.channels.compactMap({ viewState.channels[$0] }), id: \.id) { channel in
                ChannelNavigationLink(channel: channel)
            }
        }

    }
}

struct Home: View {
    @EnvironmentObject var viewState: ViewState
    
    var body: some View {
        VStack(alignment: .leading) {
            if viewState.currentServer == nil {
                HStack {
                    NavigationLink(destination: DMList.init) {
                        Avatar(user: viewState.currentUser!)
                        Text("Direct Messages")
                    }
                    
                    Spacer()
                    
                    NavigationLink(destination: Settings.init) {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                }
                .padding(.horizontal, 16)
            }

            NavigationSplitView {
                List(Array(viewState.servers), id: \.self.key, selection: $viewState.currentServer) { server in
                    NavigationLink(value: server.key) {
                        if let icon = server.value.icon {
                            LazyImage(source: .file(icon), height: 32, width: 32, clipTo: Circle())
                        }
                        
                        Text(server.value.name)
                    }
                }
            } content: {
                if let selectedServerId = viewState.currentServer {
                    let selectedServer = viewState.servers[selectedServerId]!
                    
                    let categoryChannels = selectedServer.categories?.flatMap(\.channels) ?? []
                    let nonCategoryChannels = selectedServer.channels.filter({ !categoryChannels.contains($0) })

                    List(selection: $viewState.currentChannel) {
                        if let banner = selectedServer.banner {
                            LazyImage(source: .file(banner), height: 100, clipTo: RoundedRectangle(cornerRadius: 10))
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        }

                        ForEach(nonCategoryChannels.compactMap({ viewState.channels[$0] })) { channel in
                            ChannelNavigationLink(channel: channel)
                        }
                        
                         ForEach(selectedServer.categories ?? []) { category in
                            CategorySection(category: category)
                        }
                    }
                    .listStyle(SidebarListStyle())
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            HStack {
                                if let icon = selectedServer.icon {
                                    LazyImage(source: .file(icon), height: 32, width: 32, clipTo: Circle())
                                }
                                
                                Text(selectedServer.name)
                            }
                        }
                    }
                    
                } else {
                    Text("Select a server")
                }
            } detail: {
                if let selectedChannel = viewState.currentChannel {
                    let channel = viewState.channels[selectedChannel]!
                    
                    let messages = Binding($viewState.channelMessages[channel.id])!
                    
                    MessageableChannelView(viewModel: MessageableChannelViewModel(viewState: viewState, channel: channel, messages: messages))
                } else {
                    Text("Select a channel")
                }
                
            }
        }
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home()
            .environmentObject(ViewState.preview())
            .previewLayout(.sizeThatFits)
    }
}
