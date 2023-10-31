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
            NavigationSplitView {
                List(selection: $viewState.currentServer) {
                    NavigationLink(destination: DMList.init) {
                        Avatar(user: viewState.currentUser!, withPresence: true)
                            .frame(width: 16, height: 16)
                            .frame(width: 24, height: 24)

                        Text("Direct Messages")
                    }
                    .listRowBackground(viewState.theme.background2.color)

                    Section("Servers") {
                        ForEach(viewState.servers.elements, id: \.key) { elem in
                            NavigationLink(value: elem.key) {
                                ServerIcon(server: elem.value, height: 32, width: 32)
                                Text(elem.value.name)
                            }
                        }
                    }
                    .listRowBackground(viewState.theme.background2.color)
                    
                    NavigationLink(destination: Settings.init) {
                        Image(systemName: "gearshape.fill")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .frame(width: 24, height: 24)
                        
                        Text("Settings")
                    }
                    .listRowBackground(viewState.theme.background2.color)
                }
                .scrollContentBackground(.hidden)
                .background(viewState.theme.background.color)

            } content: {
                if let selectedServerId = viewState.currentServer {
                    let selectedServer = viewState.servers[selectedServerId]!
                    
                    let categoryChannels = selectedServer.categories?.flatMap(\.channels) ?? []
                    let nonCategoryChannels = selectedServer.channels.filter({ !categoryChannels.contains($0) })

                    List(selection: $viewState.currentChannel) {
                        if let banner = selectedServer.banner {
                            LazyImage(source: .file(banner), height: 100, clipTo: RoundedRectangle(cornerRadius: 10))
                                .listRowBackground(viewState.theme.background.color)
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        }

                        ForEach(nonCategoryChannels.compactMap({ viewState.channels[$0] })) { channel in
                            ChannelNavigationLink(channel: channel)
                        }
                        .listRowBackground(viewState.theme.background2.color)
                        
                        ForEach(selectedServer.categories ?? []) { category in
                            CategorySection(category: category)
                        }
                        .listRowBackground(viewState.theme.background2.color)
                    }
                    .scrollContentBackground(.hidden)
                    .background(viewState.theme.background.color)
                    .listStyle(SidebarListStyle())
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            HStack {
                                ServerIcon(server: selectedServer, height: 32, width: 32)
                                
                                Text(selectedServer.name)
                            }
                        }
                    }
                    .toolbarBackground(viewState.theme.topBar.color, for: .automatic)
                    
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
            .background(viewState.theme.background.color)
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
