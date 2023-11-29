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
    @Binding var showSidebar: Bool
    
    var server: Server? {
        switch currentSelection {
            case .server(let serverId):
                return viewState.servers[serverId]!
            case .dms:
                return nil
        }
    }
    
    var body: some View {
        switch currentChannel {
            case .channel(let channelId):
                let channel = viewState.channels[channelId]!
                let messages = Binding($viewState.channelMessages[channelId])!
                    
                MessageableChannelView(
                    viewModel: MessageableChannelViewModel(
                        viewState: viewState,
                        channel: channel,
                        server: server,
                        messages: messages
                    ),
                    showSidebar: $showSidebar
                )
            case .server_settings:
                ServerSettings(serverId: viewState.currentServer.id!)
            case .home:
                HomeWelcome(showSidebar: $showSidebar)
            case .settings:
                VStack {
                    PageToolbar(showSidebar: $showSidebar) {
                        Image(systemName: "gearshape.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color("themePrimary"), viewState.theme.background2.color)
                            .frame(width: 16, height: 16)
                            .frame(width: 24, height: 24)
                        
                        Text("Settings")
                    }
                    Settings()
                }
            case .discover:
                VStack {
                    PageToolbar(showSidebar: $showSidebar) {
                        Image(systemName: "gearshape.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color("themePrimary"), viewState.theme.background2.color)
                            .frame(width: 16, height: 16)
                            .frame(width: 24, height: 24)
                        
                        Text("Settings")
                    }
                    Discovery()
                }
        }
    }
}

struct HomeRewritten: View {
    @EnvironmentObject var viewState: ViewState
    
    @Binding var currentSelection: MainSelection
    @Binding var currentChannel: ChannelSelection
    @State var offset = CGSize.zero
    @State var forceOpen: Bool = false
    
    @State var showJoinServerSheet = false
    
    @State var showSidebar = false
    
    var body: some View {
        if UIDevice.isIPad || UIDevice.isMac {
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
                
                MaybeChannelView(currentChannel: $currentChannel, currentSelection: $currentSelection, showSidebar: $showSidebar)
                    .frame(maxWidth: .infinity)
            }
        } else {
            GeometryReader { geo in
                let sidepanelWidth = min(geo.size.width * 0.85, 600)
                let sidepanelOffset = showSidebar ? 0 : min(-sidepanelWidth + offset.width, 0)
                
                HStack(alignment: .top, spacing: 0) {
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
                    .frame(width: sidepanelWidth)
                    .background(viewState.theme.background2.color)
                    
                    MaybeChannelView(currentChannel: $currentChannel, currentSelection: $currentSelection, showSidebar: $showSidebar)
                        .frame(maxWidth: .infinity)
                        .disabled(sidepanelOffset == 0.0)
                        .onTapGesture {
                            if sidepanelOffset == 0.0 {
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
                                        if (-sidepanelWidth + offset.width) > -100 {
                                            forceOpen = true
                                        } else if (-sidepanelWidth + offset.width) <= -100, forceOpen {
                                            forceOpen = false
                                        }
                                        
                                        offset = CGSize(width: max(g.translation.width * 2, -sidepanelWidth), height: g.translation.height)
                                    }
                                })
                                .onEnded({ v in
                                    withAnimation {
                                        if v.translation.width > 50 || forceOpen {
                                            forceOpen = false
                                            offset = CGSize(width: sidepanelWidth, height: 0)
                                        } else {
                                            offset = .zero
                                        }
                                    }
                                })
                        )
                        .offset(x: offset.width - sidepanelWidth)
                        //.ignoresSafeArea()
                        .frame(width: geo.size.width)
                }
            }
            .onChange(of: viewState.currentChannel, { before, after in
                withAnimation {
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
    
    return HomeRewritten(currentSelection: $state.currentServer, currentChannel: $state.currentChannel)
            .environmentObject(state)
}
