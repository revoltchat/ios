//
//  ServerScrollView.swift
//  Revolt
//
//  Created by Angelo Manca on 2023-11-25.
//

import SwiftUI

struct ServerScrollView: View {
    let buttonSize = 44.0
    let viewWidth = 60.0
    
    @EnvironmentObject var viewState: ViewState
    @Binding var showJoinServerSheet: Bool
    @Binding var currentSelection: MainSelection?
    
    var body: some View {
        ScrollView {
            Button(action: {
                viewState.currentServer = .dms
            }) {
                Avatar(user: viewState.currentUser!, width: buttonSize, height: buttonSize, withPresence: true)
                    .frame(width: buttonSize, height: buttonSize)
            }
            
            Divider()
                .frame(height: 30)

            Section {
                ForEach(viewState.servers.elements, id: \.key) { elem in
                    Button(action: {
                        viewState.currentServer = .server(elem.value.id)
                    }) {
                        ZStack(alignment: .bottomTrailing) {
                            ServerListIcon(server: elem.value, height: buttonSize, width: buttonSize, currentSelection: $currentSelection)
                            if let unread = viewState.getUnreadCountFor(server: elem.value) {
                                UnreadCounter(unread: unread, mentionSize: buttonSize / 2.5, unreadSize: buttonSize / 3)
                            }
                        }
                    }
                }
            }
            
            Divider()
                .frame(height: 30)
            
            Section {
                Button(action: {
                    showJoinServerSheet.toggle()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color("themePrimary"), viewState.theme.background2.color)
                        .frame(width: buttonSize, height: buttonSize)
                        .font(.system(size: buttonSize))
                }
                
                Button(action: {}) {
                    Image(systemName: "safari.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(viewState.theme.background2.color, Color("themePrimary"))
                        .frame(width: buttonSize, height: buttonSize)
                        .font(.system(size: buttonSize))
                }
                
                Button(action: {}) {
                    Image(systemName: "gearshape.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color("themePrimary"), viewState.theme.background2.color)
                        .frame(width: buttonSize, height: buttonSize)
                        .font(.system(size: buttonSize))
                }
            }

            
        }
        .scrollContentBackground(.hidden)
        .padding(.horizontal, viewWidth - buttonSize)
        .background(viewState.theme.background.color)
    }
}

#Preview(traits: .fixedLayout(width: 60, height: 500)) {
    ServerScrollView(showJoinServerSheet: .constant(false), currentSelection: .constant(MainSelection.server("0")))
        .environmentObject(ViewState.preview())
}
