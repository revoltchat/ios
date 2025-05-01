//
//  AddFriend.swift
//  Revolt
//
//  Created by Angelo on 09/03/2024.
//

import Foundation
import SwiftUI
import Types


struct AddFriend: View {
    @EnvironmentObject var viewState: ViewState
    
    @State var username: String = ""
    @State var error: String? = nil
    @State var message: String? = nil
    
    @FocusState var usernameFocus: Bool
    
    var body: some View {
        VStack(alignment: .center) {
            Text("Add a friend")
                .font(.title)
                .bold()
            
            TextField("username#1234", text: $username)
                .focused($usernameFocus)
                .padding(16)
                .background(viewState.theme.background2)
                .addBorder(viewState.theme.background2, cornerRadius: 16)
            
            if let error {
                Text(verbatim: error)
                    .foregroundStyle(viewState.theme.error)
                    .font(.caption)
            }
            
            if let message {
                Text(verbatim: message)
                    .foregroundStyle(viewState.theme.success)
                    .font(.caption)
            }
            
            Spacer()
            
            Button {
                Task {
                    error = nil
                    message = nil

                    if username.range(of: "^[^ ]+#[0-9]{4}$", options: .regularExpression) == nil {
                        error = "Username is not valid, make sure to include the discriminator"
                        return
                    }
                    
                    if case .failure(let e) = await viewState.http.sendFriendRequest(username: username) {
                        error = e.localizedDescription
                        return
                    }
                    
                    message = "Successfully send a friend request to \(username)."
                }
            } label: {
                Text("Send Friend Request")
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(viewState.theme.accent)
            .clipShape(Capsule())
        }
        .onAppear { usernameFocus = true }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
        .background(viewState.theme.background)
    }
}
