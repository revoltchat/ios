//
//  ShareInviteSheet.swift
//  Revolt
//
//  Created by Angelo on 09/03/2024.
//

import Foundation
import SwiftUI
import Types

struct ShareInviteSheet: View {
    @EnvironmentObject var viewState: ViewState
    
    @State var channel: Channel
    @State var url: URL
    @State var friendSearch: String = ""
    @State var copiedToClipboard: Bool = false
    
    func getFriends() ->  [User] {
        var friends: [User] = []
        
        for user in viewState.users.values {
            switch user.relationship ?? .None {
                case .Friend:
                    friends.append(user)
                default:
                    ()
            }
        }
        
        return friends
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Invite another user")
                .bold()
            
            HStack {
                ShareLink(item: url) {
                    VStack {
                        Image(systemName: "square.and.arrow.up.circle")
                            .resizable()
                            .frame(width: 32, height: 32)
                        
                        Text("Share Invite")
                            .font(.footnote)
                    }
                }
                
                Button {
                    copyUrl(url: url)
                    
                    withAnimation(.snappy) {
                        copiedToClipboard = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.snappy) {
                            copiedToClipboard = false
                        }
                    }
                } label: {
                    VStack {
                        Image(systemName: "link.circle")
                            .resizable()
                            .frame(width: 32, height: 32)
                        
                        Text("Copy Link")
                            .font(.footnote)
                    }
                }
            }
            
            Divider()
            
            VStack {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .resizable()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(viewState.theme.foreground2)
                    
                    TextField("Invite your friends", text: $friendSearch)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(viewState.theme.background2)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 16)
                
                List {
                    ForEach(getFriends().filter { user in friendSearch.isEmpty || (user.username.contains(friendSearch) || (user.display_name?.contains(friendSearch) ?? false))}) { user in
                        HStack(spacing: 12) {
                            Avatar(user: user)
                                .frame(width: 16, height: 16)
                                .frame(width: 24, height: 24)
                            
                            Text(user.display_name ?? user.username)
                            
                            Spacer()
                            
                            Text("Invite")
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(viewState.theme.background3, in: RoundedRectangle(cornerRadius: 50))
                        }
                        .listRowBackground(viewState.theme.background2)
                    }
                }
                .scrollContentBackground(.hidden)
                .listRowInsets(.none)
            }
        }
        .padding(.top, 8)
        .background(viewState.theme.background)
        .overlay {
            if copiedToClipboard {
                Text("Copied to Clipboard")
                    .fontWeight(.semibold)
                    .foregroundStyle(viewState.theme.foreground)
                    .padding()
                    .background(viewState.theme.accent, in: RoundedRectangle(cornerRadius: 20))
                    .padding(.bottom)
                    .shadow(radius: 5)
                    .transition(.move(edge: .bottom))
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
    }
}

#Preview {
    let viewState = ViewState.preview()

    return ShareInviteSheet(channel: viewState.channels["0"]!, url: URL(string: "https://revolt.chat")!)
        .applyPreviewModifiers(withState: viewState)
}
