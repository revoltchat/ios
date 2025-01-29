//
//  CreateGroup.swift
//  Revolt
//
//  Created by Angelo on 09/03/2024.
//

import Foundation
import SwiftUI
import Types

struct CreateGroup: View {
    @EnvironmentObject var viewState: ViewState
    
    @State var searchText: String = ""
    @State var selectedUsers: Set<User> = Set()
    @State var error: String? = nil
    
    @State var allFriends: [User] = []
    
    var body: some View {
        VStack(spacing: 4) {
            if let error = error {
                Text(verbatim: error)
                    .foregroundStyle(viewState.theme.accent)
                    .bold()
            }

            TextField("Search for friends", text: $searchText)
                .padding(8)
                .background(viewState.theme.background2)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding([.horizontal, .top], 16)
            
            List(selection: $selectedUsers) {
                ForEach(allFriends.filter { user in searchText.isEmpty || (user.username.contains(searchText) || (user.display_name?.contains(searchText) ?? false))}) { user in
                    let binding = Binding(
                        get: { selectedUsers.contains(user) },
                        set: { v in
                            if v {
                                if selectedUsers.count < 99 {
                                    selectedUsers.insert(user)
                                }
                            } else {
                                selectedUsers.remove(user)
                            }
                        }
                    )

                    Toggle(isOn: binding) {
                        HStack(spacing: 12) {
                            Avatar(user: user)
                                .frame(width: 16, height: 16)
                                .frame(width: 24, height: 24)
                            
                            Text(user.display_name ?? user.username)
                        }
                        .padding(.leading, 12)
                    }
                    .toggleStyle(CheckboxStyle())
                    .listRowBackground(viewState.theme.background2)
                }
            }
            .scrollContentBackground(.hidden)
            #if os(iOS)
            .environment(\.editMode, .constant(EditMode.active))
            #endif
        }
        .task {
            allFriends = viewState.users.values.filter({ user in
                switch user.relationship ?? .None {
                    case .Friend:
                        return true
                    default:
                        return false
                }
            })
        }
        .background(viewState.theme.background.color)
        .toolbarBackground(viewState.theme.topBar.color, for: .automatic)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(alignment: .center) {
                    Text("New Group")
                    Text("\(selectedUsers.count + 1) of 100 members")
                        .font(.caption)
                }
            }
        }
        .toolbar {
#if os(iOS)
            let placement = ToolbarItemPlacement.topBarTrailing
#elseif os(macOS)
            let placement = ToolbarItemPlacement.automatic
#endif
            ToolbarItem(placement: placement) {
                Button {
                    Task {
                        let res = await viewState.http.createGroup(name: "New Group", users: selectedUsers.map(\.id))
                        switch res {
                            case .success(let c):
                                viewState.channels[c.id] = c
                                viewState.channelMessages[c.id] = []
                                viewState.currentChannel = .channel(c.id)
                                viewState.path = NavigationPath()
                            case .failure(_):
                                error = "Failed to create group."
                        }
                    }
                } label: {
                    Text("Create")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CreateGroup()
            .applyPreviewModifiers(withState: ViewState.preview())
    }
}
