//
//  FriendsList.swift
//  Revolt
//
//  Created by Angelo on 14/11/2023.
//

import Foundation
import SwiftUI

struct Friends {
    var outgoing: [User]
    var incoming: [User]
    var friends: [User]
    var blocked: [User]
    var blockedBy: [User]
}

struct FriendsList: View {
    @EnvironmentObject var viewState: ViewState
    
    @State var selectedUser: User? = nil

    func getFriends() ->  Friends {
        var friends = Friends(outgoing: [], incoming: [], friends: [], blocked: [], blockedBy: [])
        
        for user in viewState.users.values {
            switch user.relationship ?? .None {
                case .Blocked:
                    friends.blocked.append(user)
                case .BlockedOther:
                    friends.blockedBy.append(user)
                case .Friend:
                    friends.friends.append(user)
                case .Incoming:
                    friends.incoming.append(user)
                case .Outgoing:
                    friends.outgoing.append(user)
                default:
                    break
            }
        }
        
        return friends
    }
    
    var body: some View {
        let friends = getFriends()
        
        List {
            let arr = [
                ("Incoming", friends.incoming),
                ("Outgoing", friends.outgoing),
                ("Friends", friends.friends),
                ("Blocked", friends.blocked),
                ("Blocked By", friends.blockedBy)
            ].filter({ !$0.1.isEmpty })
            
            Section {
                Button {
                    
                } label: {
                    HStack {
                        Image(systemName: "person.crop.circle.fill.badge.plus")
                            .resizable()
                            //.frame(width: 16, height: 16)
                            .frame(width: 24, height: 24)
                        
                        Text("Add Friend")
                    }
                }
            }
            .listRowBackground(viewState.theme.background2.color)

            ForEach(arr, id: \.0) { (title, users) in
                Section {
                    ForEach(users) { user in
                        Button {
                            selectedUser = user
                        } label: {
                            HStack(spacing: 12) {
                                Avatar(user: user)
                                    .frame(width: 16, height: 16)
                                    .frame(width: 24, height: 24)
                                
                                Text(user.username)
                                
                                Spacer()
                                
                                if user.relationship == .Incoming {
                                    Button {
                                        Task {
                                            if case .success(_) = await viewState.http.acceptFriendRequest(user: user.id) {
                                                viewState.users[user.id]!.relationship = .Friend
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "checkmark.circle.fill")
                                            .resizable()
                                            .foregroundStyle(viewState.theme.foreground2.color)
                                            .frame(width: 16, height: 16)
                                            .frame(width: 24, height: 24)
                                    }
                                }
                                
                                if [.Incoming, .Outgoing, .Friend].contains(user.relationship) {
                                    Button {
                                        Task {
                                            if case .success(_) = await viewState.http.removeFriend(user: user.id) {
                                                viewState.users[user.id]!.relationship = .None
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "x.circle.fill")
                                            .resizable()
                                            .foregroundStyle(viewState.theme.foreground2.color)
                                            .frame(width: 16, height: 16)
                                            .frame(width: 24, height: 24)
                                    }
                                }
                                
                                if user.relationship == .Blocked {
                                    Button {
                                        Task {
                                            if case .success(_) = await viewState.http.unblockUser(user: user.id) {
                                                viewState.users[user.id]!.relationship = .None
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "person.crop.circle.fill.badge.xmark")
                                            .resizable()
                                            .foregroundStyle(viewState.theme.foreground2.color)
                                            .frame(width: 16, height: 16)
                                            .frame(width: 24, height: 24)
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text(title)
                        Spacer()
                        Text("\(users.count)")
                    }
                }
                .listRowBackground(viewState.theme.background2.color)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(viewState.theme.background.color)
        .sheet(item: $selectedUser, content: { user in
            UserSheet(user: .constant(user), member: .constant(nil))
        })
    }
}
