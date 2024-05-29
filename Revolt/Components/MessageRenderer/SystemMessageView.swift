//
//  SystemMessageView.swift
//  Revolt
//
//  Created by Angelo on 12/12/2023.
//

import Foundation
import SwiftUI
import Types

struct SystemMessageView: View {
    @EnvironmentObject var viewState: ViewState
    @Binding var message: Message

    var body: some View {
        HStack {
            switch message.system! {
                case .user_joined(let content):
                    let user = viewState.users[content.id]!
                    Image(systemName: "arrow.forward")
                    Avatar(user: user, masquerade: message.masquerade)
                    Text(user.username)
                    Text("Joined")
                default:
                    Text("unknown")
            }
        }
    }
}
