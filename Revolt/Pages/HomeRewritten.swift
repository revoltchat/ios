//
//  HomeRewritten.swift
//  Revolt
//
//  Created by Angelo on 25/11/2023.
//
import SwiftUI

struct MaybeChannelView: View {
    @EnvironmentObject var viewState: ViewState
    @Binding var currentChannel: ChannelSelection
    @Binding var currentSelection: MainSelection
    @Binding var currentServer: Server?
    @Binding var showSidebar: Bool
    
    var body: some View {
        switch currentChannel {
            case .channel(let channelId):
                let channel = viewState.channels[channelId]!
                let messages = Binding($viewState.channelMessages[channelId])!
                    
                MessageableChannelView(
                    viewModel: MessageableChannelViewModel(
                        viewState: viewState,
                        channel: channel,
                        server: currentServer,
                        messages: messages
                    ),
                    showSidebar: $showSidebar
                )
            case .home:
                HomeWelcome(showSidebar: $showSidebar)
            case .friends:
                VStack(spacing: 0) {
                    PageToolbar(showSidebar: $showSidebar) {
                        Image(systemName: "person.3.sequence")
                            .frame(width: 16, height: 16)
                            .frame(width: 24, height: 24)
                        
                        Text("Friends")
                    } trailing: {
                        EmptyView()
                    }
                    
                    FriendsList()
                }
                .background(viewState.theme.background.color)
        }
    }
}

struct HomeRewritten: View {
    @EnvironmentObject var viewState: ViewState
    
    @Binding var currentSelection: MainSelection
    @Binding var currentChannel: ChannelSelection
    @State var currentServer: Server?
    
    @State var offset = CGFloat.zero
    @State var forceOpen: Bool = false
    
    @State var showJoinServerSheet = false
    
    @State var showSidebar = false
    
    var body: some View {
        if isIPad || isMac {
            HStack(spacing: 0) {
                HStack(spacing: 0) {
                    ServerScrollView(showJoinServerSheet: $showJoinServerSheet)
                        .frame(maxWidth: 60)
                    
                    switch currentSelection {
                        case .server(_):
                            ServerChannelScrollView(currentSelection: $currentSelection, currentChannel: $currentChannel)
                        case .dms:
                            DMScrollView(currentChannel: $currentChannel)
                    }
                }
                .frame(maxWidth: 300)
                
                MaybeChannelView(currentChannel: $currentChannel, currentSelection: $currentSelection, currentServer: $currentServer, showSidebar: $showSidebar)
                    .frame(maxWidth: .infinity)
            }
        } else {
            GeometryReader { geo in
                let width = min(geo.size.width * 0.85, 600)
                
                ZStack(alignment: .topLeading) {
                    HStack(spacing: 0) {
                        ServerScrollView(showJoinServerSheet: $showJoinServerSheet)
                            .frame(maxWidth: 60)
                        
                        switch currentSelection {
                            case .server(_):
                                ServerChannelScrollView(currentSelection: $currentSelection, currentChannel: $currentChannel)

                            case .dms:
                                DMScrollView(currentChannel: $currentChannel)
                        }
                    }
                    .frame(width: width)
                    .background(viewState.theme.background2.color)
                    
                    MaybeChannelView(currentChannel: $currentChannel, currentSelection: $currentSelection, currentServer: $currentServer, showSidebar: $showSidebar)
                        .disabled(offset != 0.0)
                        .onTapGesture {
                            if offset == 0.0 {
                                withAnimation {
                                    showSidebar = false
                                    offset = .zero
                                }
                            }
                        }
                        .gesture(
                            DragGesture()
                                .onChanged({ g in
                                    withAnimation {
                                        if offset > 100 {
                                            forceOpen = true
                                        } else if offset <= 100, forceOpen {
                                            forceOpen = false
                                        }
                                        
                                        offset = min(max(g.translation.width - 50, 0), width)
                                    }
                                })
                                .onEnded({ v in
                                    withAnimation {
                                        if v.translation.width > 100 || forceOpen {
                                            forceOpen = false
                                            offset = width
                                        } else {
                                            offset = .zero
                                        }
                                    }
                                })
                        )
                        .offset(x: offset)
                        .frame(width: geo.size.width)
                }
                .onChange(of: showSidebar) { (_, after) in
                    if after {
                        offset = min(geo.size.width * 0.85, 600)
                        showSidebar = false
                    }
                }
            }
            .onChange(of: viewState.currentChannel, { before, after in
                withAnimation {
                    // a seperate current server state is used to avoid setting the server to nil while switching to dms in the sidepanel but not switched channels yet
                    // causing the state to be invalid as we have no server but inside a server channel, having a seperate state which only updates when switching channels
                    // fixes this
                    currentServer = currentSelection.id.flatMap { viewState.servers[$0] }
                    
                    showSidebar = false
                    currentChannel = after
                    forceOpen = false
                    offset = .zero
                }
            })
            .onChange(of: viewState.currentServer) { before, after in
                withAnimation {
                    currentSelection = after
                }
            }
        }
    }
}

#Preview {
    @StateObject var state = ViewState.preview().applySystemScheme(theme: .dark)
    
    return HomeRewritten(currentSelection: $state.currentServer, currentChannel: $state.currentChannel, currentServer: nil)
            .environmentObject(state)
}
