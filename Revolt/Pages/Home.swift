import SwiftUI
import OrderedCollections

struct ChannelNavigationLink: View {
    var channel: Channel
    
    var body: some View {
        NavigationLink(value: ChannelSelection.channel(channel.id)) {
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
    @State var showJoinServerSheet: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            NavigationSplitView {
                List(selection: $viewState.currentServer) {
                    NavigationLink(value: MainSelection.dms) {
                        Avatar(user: viewState.currentUser!, withPresence: true)
                            .frame(width: 16, height: 16)
                            .frame(width: 24, height: 24)

                        Text("Direct Messages")
                    }
                    .listRowBackground(viewState.theme.background2.color)

                    Section("Servers") {
                        ForEach(viewState.servers.elements, id: \.key) { elem in
                            NavigationLink(value: MainSelection.server(elem.key)) {
                                HStack(spacing: 12) {
                                    ServerIcon(server: elem.value, height: 32, width: 32)
                                    Text(elem.value.name)
                                }
                            }
                        }
                    }
                    .listRowBackground(viewState.theme.background2.color)
                    
                    Button {
                        showJoinServerSheet.toggle()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus")
                                .resizable()
                                .frame(width: 16, height: 16)
                                .frame(width: 24, height: 24)
                            
                            Text("Add a server")
                        }
                    }
                    .listRowBackground(viewState.theme.background2.color)
                    
                    NavigationLink(destination: Settings.init) {
                        HStack(spacing: 12) {
                            Image(systemName: "gearshape.fill")
                                .resizable()
                                .frame(width: 16, height: 16)
                                .frame(width: 24, height: 24)
                            
                            Text("Settings")
                        }
                    }
                    .listRowBackground(viewState.theme.background2.color)
                    
                }
                .scrollContentBackground(.hidden)
                .background(viewState.theme.background.color)

            } content: {
                switch viewState.currentServer {
                    case .server(let selectedServerId):
                        let selectedServer = viewState.servers[selectedServerId]!
                        
                        let categoryChannels = selectedServer.categories?.flatMap(\.channels) ?? []
                        let nonCategoryChannels = selectedServer.channels.filter({ !categoryChannels.contains($0) })
                        
                        List(selection: $viewState.currentChannel) {
                            if let banner = selectedServer.banner {
                                if nonCategoryChannels.isEmpty {
                                    LazyImage(source: .file(banner), height: 100, clipTo: RoundedRectangle(cornerRadius: 10))
                                        .listRowBackground(viewState.theme.background.color)
                                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                    
                                } else {
                                    LazyImage(source: .file(banner), height: 100, clipTo: UnevenRoundedRectangle(topLeadingRadius: 10, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 10, style: .continuous))
                                        .listRowBackground(viewState.theme.background.color)
                                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                }
                            }
                            
                            ForEach(nonCategoryChannels.compactMap({ viewState.channels[$0] })) { channel in
                                ChannelNavigationLink(channel: channel)
                            }
                            .listRowBackground(viewState.theme.background2.color)
                            
                            ForEach(selectedServer.categories ?? []) { category in
                                CategorySection(category: category)
                            }
                            .listRowBackground(viewState.theme.background2.color)
                            
                            Section {
                                NavigationLink(value: ChannelSelection.server_settings) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "gearshape.fill")
                                            .resizable()
                                            .frame(width: 16, height: 16)
                                            .frame(width: 24, height: 24)
                                        
                                        Text("Settings")
                                    }
                                }
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

                    case .dms:
                        List(selection: $viewState.currentChannel) {
                            NavigationLink(destination: FriendsList.init) {
                                Image(systemName: "person.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .resizable()
                                    .frame(width: 16, height: 16)
                                    .frame(width: 24, height: 24)
                                
                                Text("Friends")
                            }
                            .listRowBackground(viewState.theme.background2.color)
                            
                            let channel: SavedMessages = viewState.dms.compactMap { channel in
                                if case .saved_messages(let c) = channel {
                                    return c
                                }
                                
                                return nil
                            }.first!
                            
                            NavigationLink(value: channel.id) {
                                ChannelIcon(channel: .saved_messages(channel))
                            }
                            .listRowBackground(viewState.theme.background2.color)
                            
                            Section("Conversations") {
                                ForEach(viewState.dms.filter {
                                    switch $0 {
                                        case .saved_messages(_):
                                            return false
                                        default:
                                            return true
                                    }
                                }) { channel in
                                    NavigationLink(value: channel.id) {
                                        ChannelIcon(channel: channel)
                                    }
                                }
                            }
                            .listRowBackground(viewState.theme.background2.color)
                        }
                        .scrollContentBackground(.hidden)
                        .background(viewState.theme.background.color)
                        .listStyle(SidebarListStyle())
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                HStack {
                                    Avatar(user: viewState.currentUser!, width: 32, height: 32)
                                    
                                    Text("Direct Messages")
                                }
                            }
                        }
                        .toolbarBackground(viewState.theme.topBar.color, for: .automatic)
                    case nil:
                        Text("Select a server")
                }
            } detail: {
                if let selectedChannel = viewState.currentChannel {
                    switch selectedChannel {
                        case .channel(let channelId):
                            let channel = viewState.channels[channelId]!
                            
                            let messages = Binding($viewState.channelMessages[channelId])!
                            
                            MessageableChannelView(viewModel: MessageableChannelViewModel(viewState: viewState, channel: channel, messages: messages))
                        case .server_settings:
                            ServerSettings(serverId: viewState.currentServer!.id!)
                    }
                } else {
                    Text("Select a channel")
                }
                
            }
            .background(viewState.theme.background.color)
            .sheet(isPresented: $showJoinServerSheet, content: JoinServer.init)
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
