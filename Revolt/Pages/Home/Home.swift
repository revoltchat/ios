//
//  HomeRewritten.swift
//  Revolt
//
//  Created by Angelo on 25/11/2023.
//
import SwiftUI
import Types

struct MaybeChannelView: View {
    @EnvironmentObject var viewState: ViewState
    @Binding var currentChannel: ChannelSelection
    @Binding var currentSelection: MainSelection
    var toggleSidebar: () -> ()
    @Binding var disableScroll: Bool
    @Binding var disableSidebar: Bool
    
    var body: some View {
        switch currentChannel {
            case .channel(let channelId):
                if let channel = viewState.channels[channelId] {
                    let messages = Binding($viewState.channelMessages[channelId])!
                    
                    MessageableChannelView(
                        viewModel: MessageableChannelViewModel(
                            viewState: viewState,
                            channel: channel,
                            server: currentSelection.id.map { viewState.servers[$0]! },
                            messages: messages
                        ),
                        toggleSidebar: toggleSidebar,
                        disableScroll: $disableScroll,
                        disableSidebar: $disableSidebar
                    )

                } else {
                    Text("Unknown Channel :(")
                }
            case .home:
                HomeWelcome(toggleSidebar: toggleSidebar)
            case .friends:
                VStack(spacing: 0) {
                    PageToolbar(toggleSidebar: toggleSidebar) {
                        Image(systemName: "person.3.sequence")
                            .frame(width: 16, height: 16)
                            .frame(width: 24, height: 24)
                        
                        Text("Friends")
                    }
                    
                    FriendsList()
                }
                .background(viewState.theme.background.color)
            case .noChannel:
                Text("Looks a bit empty in here.")
        }
    }
}

struct HomeRewritten: View {
    @EnvironmentObject var viewState: ViewState
    
    @Binding var currentSelection: MainSelection
    @Binding var currentChannel: ChannelSelection
    
    @State var offset = CGFloat.zero
    @State var forceOpen: Bool = false
    @State var calculatedSize = CGFloat.zero
    @State var disableScroll = false
    @State var disableSidebar = false
    
    var minGestureLength: CGFloat = 20
    
    func toggleSidebar() {
        withAnimation {
            if offset != .zero {
                offset = .zero
            } else {
                offset = calculatedSize
            }
        }
    }
    
    var body: some View {
        if isIPad || isMac {
            HStack(spacing: 0) {
                HStack(spacing: 0) {
                    ServerScrollView()
                        .frame(maxWidth: 60)
                    
                    switch currentSelection {
                        case .server(_):
                            ServerChannelScrollView(currentSelection: $currentSelection, currentChannel: $currentChannel, toggleSidebar: toggleSidebar)
                        case .dms:
                            DMScrollView(currentChannel: $currentChannel, toggleSidebar: toggleSidebar)
                    }
                }
                .frame(maxWidth: 300)
                
                MaybeChannelView(currentChannel: $currentChannel, currentSelection: $currentSelection, toggleSidebar: toggleSidebar, disableScroll: $disableScroll, disableSidebar: $disableSidebar)
                    .frame(maxWidth: .infinity)
            }
        } else {
            GeometryReader { geo in
                let sidebarWidth = min(geo.size.width * 0.85, 600)
                let snapSide = sidebarWidth * (1 / 3)
                
                ZStack(alignment: .topLeading) {
                    HStack(spacing: 0) {
                        ServerScrollView()
                            .frame(maxWidth: 60)
                        
                        switch currentSelection {
                            case .server(_):
                                ServerChannelScrollView(currentSelection: $currentSelection, currentChannel: $currentChannel, toggleSidebar: toggleSidebar)

                            case .dms:
                                DMScrollView(currentChannel: $currentChannel, toggleSidebar: toggleSidebar)
                        }
                    }
                    .frame(width: sidebarWidth)
                    .background(viewState.theme.background2.color)
                    
                    ZStack {
                        viewState.theme.messageBox
                            .offset(x: offset)
                            .frame(width: geo.size.width)
                            .ignoresSafeArea(.all)
                        
                        MaybeChannelView(currentChannel: $currentChannel, currentSelection: $currentSelection, toggleSidebar: toggleSidebar, disableScroll: $disableScroll, disableSidebar: $disableSidebar)
                            .disabled(offset != 0.0)
                            .offset(x: offset)
                            .frame(width: geo.size.width)
                            .onTapGesture {
                                if offset != 0.0 {
                                    withAnimation(.easeInOut) {
                                        offset = .zero
                                    }
                                }
                            }
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: minGestureLength)
                                .onChanged({ g in
                                    if g.translation.width >= minGestureLength {
                                        disableScroll = true
                                    }
                                    
                                    if offset > snapSide {
                                        forceOpen = true
                                    } else if offset <= snapSide {
                                        forceOpen = false
                                    }
                                        
                                    withAnimation {
                                        offset = min(max(g.translation.width, 0), sidebarWidth)
                                    }
                                })
                                .onEnded({ v in
                                    disableScroll = false
                                    
                                    withAnimation(.easeInOut) {
                                        if forceOpen {
                                            forceOpen = false
                                            offset = sidebarWidth
                                        } else {
                                            offset = .zero
                                        }
                                    }
                                }),
                        isEnabled: !disableSidebar
                        )
                }
                .task { calculatedSize = sidebarWidth }
            }
//            .onChange(of: viewState.currentChannel, { before, after in
//                withAnimation(.easeInOut) {
//                    showSidebar = false
//                    forceOpen = false
//                    offset = .zero
//                }
//            })
//            .onChange(of: viewState.currentSelection) { before, after in
//                withAnimation {
//                    switch after {
//                        case .dms:
//                            if let last = viewState.userSettingsStore.store.lastOpenChannels["dms"] {
//                                currentChannel = .channel(last)
//                            } else {
//                                currentChannel = .home
//                            }
//                        case .server(let id):
//                            if let last = viewState.userSettingsStore.store.lastOpenChannels[id] {
//                                currentChannel = .channel(last)
//                            } else if let server = viewState.servers[id] {
//                                if let firstChannel = server.channels.compactMap({
//                                    switch viewState.channels[$0] {
//                                        case .text_channel(let c):
//                                            return c
//                                        default:
//                                            return nil
//                                    }
//                                }).first {
//                                    currentChannel = .channel(firstChannel.id)
//                                } else {
//                                    currentChannel = .noChannel
//                                }
//                            }
//                    }
//                }
//            }
        }
    }
}

#Preview {
    @StateObject var state = ViewState.preview().applySystemScheme(theme: .dark)
    
    return HomeRewritten(currentSelection: $state.currentSelection, currentChannel: $state.currentChannel)
            .environmentObject(state)
}
