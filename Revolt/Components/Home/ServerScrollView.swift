//
//  ServerScrollView.swift
//  Revolt
//
//  Created by Angelo Manca on 2023-11-25.
//

import SwiftUI
import Types

struct ServerScrollView: View {
    let buttonSize = 44.0
    let viewWidth = 60.0
    
    @EnvironmentObject var viewState: ViewState
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                Spacer()
                    .frame(height: buttonSize + 12 + 8)
                Section {
                    ForEach(viewState.servers.elements, id: \.key) { elem in
                        Button {
                            withAnimation {
                                viewState.currentSelection = .server(elem.value.id)
                                
                                if let last = viewState.userSettingsStore.store.lastOpenChannels[elem.value.id] {
                                    viewState.currentChannel = .channel(last)
                                } else if let server = viewState.servers[elem.value.id] {
                                    if let firstChannel = server.channels.compactMap({
                                        switch viewState.channels[$0] {
                                            case .text_channel(let c):
                                                return c
                                            default:
                                                return nil
                                        }
                                    }).first {
                                        viewState.currentChannel = .channel(firstChannel.id)
                                    } else {
                                        viewState.currentChannel = .noChannel
                                    }
                                }
                            }
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                ServerListIcon(server: elem.value, height: buttonSize, width: buttonSize, currentSelection: $viewState.currentSelection)
                                
                                if let unread = viewState.getUnreadCountFor(server: elem.value) {
                                    ZStack(alignment: .center) {
                                        Circle()
                                            .foregroundStyle(.black)
                                            .frame(width: (buttonSize / 3) + 6, height: (buttonSize / 3) + 6)
                                            .blendMode(.destinationOut)
                                        
                                        UnreadCounter(unread: unread, mentionSize: buttonSize / 2.5, unreadSize: buttonSize / 3)
                                            .background(viewState.theme.foreground)
                                            .containerShape(Circle())
                                    }
                                    .padding(.top, -2)
                                    .padding(.trailing, -2)
                                }
                            }
                            .compositingGroup()
                        }
                        .padding(.vertical, 2)
                    }
                }
                
                Divider()
                    .frame(height: 12)
                
                Section {
                    NavigationLink(value: NavigationDestination.add_server) {
                        Image(systemName: "plus.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(viewState.theme.accent.color, viewState.theme.background2.color)
                            .frame(width: buttonSize, height: buttonSize)
                            .font(.system(size: buttonSize))
                    }
                    
                    NavigationLink(value: NavigationDestination.discover) {
                        Image(systemName: "safari.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(viewState.theme.accent.color, viewState.theme.background2.color)
                            .frame(width: buttonSize, height: buttonSize)
                            .font(.system(size: buttonSize))
                    }
                    
                    NavigationLink(value: NavigationDestination.settings) {
                        Image(systemName: "gearshape.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(viewState.theme.accent.color, viewState.theme.background2.color)
                            .frame(width: buttonSize, height: buttonSize)
                            .font(.system(size: buttonSize))
                    }
                }
                
                
            }
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            
            VStack {
                Button(action: {
                    viewState.currentSelection = .dms
                    
                    if let last = viewState.userSettingsStore.store.lastOpenChannels["dms"] {
                        viewState.currentChannel = .channel(last)
                    } else {
                        viewState.currentChannel = .home
                    }
                }) {
                    if viewState.currentUser != nil {
                        Avatar(user: viewState.currentUser!, width: buttonSize, height: buttonSize, withPresence: true)
                            .frame(width: buttonSize, height: buttonSize)
                    }
                }
                
                Divider()
            }
            .background(viewState.theme.background)
        }
        .padding(.horizontal, viewWidth - buttonSize)
        .background(viewState.theme.background)
    }
}

#Preview(traits: .fixedLayout(width: 60, height: 500)) {
    ServerScrollView()
        .applyPreviewModifiers(withState: ViewState.preview().applySystemScheme(theme: .light))
}
