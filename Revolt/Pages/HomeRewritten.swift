//
//  HomeRewritten.swift
//  Revolt
//
//  Created by Angelo on 25/11/2023.
//
import SwiftUI

struct MaybeChannelView: View {
    @EnvironmentObject var viewState: ViewState
    @Binding var currentChannel: ChannelSelection?
    @Binding var currentSelection: MainSelection?
    
    var body: some View {
        switch currentSelection {
        case .server(let serverId):
            switch currentChannel {
                case .channel(let channelId):
                    let channel = viewState.channels[channelId]!
                    let messages = Binding($viewState.channelMessages[channelId])!
                    let server = viewState.servers[serverId]!
                        
                    MessageableChannelView(
                        viewModel: MessageableChannelViewModel(
                            viewState: viewState,
                            channel: channel,
                            server: server,
                            messages: messages
                        )
                    )
                case .server_settings:
                    ServerSettings(serverId: viewState.currentServer!.id!)
                default:
                    Text("It's rather empty in here...")
            }
        case .dms:
            Text("It's rather empty in here...")
        default:
            Text("It's rather empty in here")
        }
    }
}

struct HomeRewritten: View {
    @EnvironmentObject var viewState: ViewState
    
    @State var currentSelection: MainSelection? = nil
    @State var currentChannel: ChannelSelection? = nil
    @State var offset = CGSize.zero
    @State var forceOpen: Bool = false
    
    @State var showJoinServerSheet = false
    
    @State var didInitialize = false
    
    func lateInit() { // environment objects arent passed until body is called, so we do this on body appear
        if !didInitialize {
            didInitialize = true

            let state = viewState
            currentSelection = state.currentServer
            currentChannel = state.currentChannel
            offset = CGSize.zero
            forceOpen = false
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            let sidepanelWidth = min(geo.size.width * 0.85, 600)
            let sidepanelOffset = min(-sidepanelWidth + offset.width, 0)
    
            ZStack(alignment: .topLeading) {
                MaybeChannelView(currentChannel: $currentChannel, currentSelection: $currentSelection)
                    .disabled(sidepanelOffset == 0.0)
                    .onTapGesture {
                        print(sidepanelOffset)
                        if sidepanelOffset == 0.0 {
                            withAnimation {
                                offset = .zero
                            }
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged({ g in
                                if (-sidepanelWidth + offset.width) > -200 {
                                    forceOpen = true
                                } else if (-sidepanelWidth + offset.width) < -200, forceOpen {
                                    forceOpen = false
                                }
        
                                offset = g.translation
                            })
                            .onEnded({ v in
                                if v.translation.width > 50 || forceOpen {
                                    forceOpen = false
                                    offset = CGSize(width: sidepanelWidth, height: 0)
                                } else {
                                    offset = .zero
                                }
                            })
                    )
                
                HStack(spacing: 0) {
                    ServerScrollView(showJoinServerSheet: $showJoinServerSheet, currentSelection: $currentSelection)
                        .frame(maxWidth: 60)
                        .padding(.leading, 10)
                    
                    switch currentSelection {
                    case .server(_):
                        ServerChannelScrollView(currentSelection: $currentSelection, currentChannel: $currentChannel)
                            .padding(.leading, 20)
                    case .dms:
                        ZStack {}
                    default:
                        VStack {
                            Text("Its rather empty in here...")
                        }
                    }
                }
                .frame(maxWidth: sidepanelWidth, maxHeight: .infinity)
                .background(viewState.theme.background2.color)
                .transition(.move(edge: .leading))
                .offset(CGSize(width: sidepanelOffset, height: 0.0))
                .gesture(
                    DragGesture()
                        .onChanged({ g in
                            offset = CGSize(width: offset.width + min(g.translation.width, 0), height: offset.height)
                        })
                )
            }
        }
        .onChange(of: viewState.currentChannel, { before, after in
            switch after {
            case .channel(_), .server_settings:
                    withAnimation {
                        currentChannel = after
                        forceOpen = false
                        offset = CGSize(width: 0.0, height: offset.height)
                    }
                default: ()
            }
        })
        .onChange(of: viewState.currentServer) { before, after in
            withAnimation {
                currentSelection = after
            }
        }
        .onAppear {
            lateInit()
        }
    }
}

#Preview {
    let state = ViewState.preview()
    return HomeRewritten()
            .environmentObject(state)
}
