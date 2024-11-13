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
        HStack(alignment: .center) {
            switch message.system! {
                case .user_joined(let content):
                    let user = viewState.users[content.id]!
                    let member = viewState.channels[message.channel]!.server.flatMap { viewState.members[$0]?[user.id] }
                    
                    Image(systemName: "arrow.forward")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    
                    Avatar(user: user, member: member, masquerade: message.masquerade, width: 24, height: 24)
                    
                    Text("\(member?.nickname ?? user.display_name ?? user.username) joined")

                default:
                    Text("unknown")
            }
        }
    }
}
