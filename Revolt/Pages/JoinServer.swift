//
//  JoinServer.swift
//  Revolt
//
//  Created by Angelo on 01/11/2023.
//

import Foundation
import SwiftUI

struct JoinServer: View {
    @EnvironmentObject var viewState: ViewState
    @State var showAlert: Bool = false
    @State var inviteCode: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add a server")
                .font(.title)
            
            Button {
                showAlert.toggle()
            } label: {
                HStack {
                    Image(systemName: "arrow.right.square")
                        .resizable()
                        .frame(width: 24, height: 24)

                    Text("Join by invite code or link")
                        .font(.title3)
                }
            }
            .alert("Join Server", isPresented: $showAlert) {
                Button {
                    
                } label: {
                    Text("Cancel")
                }
                
                Button {
                    Task {
                        let joinResponse = await viewState.joinServer(code: inviteCode)
                        viewState.currentServer = .server(joinResponse.server.id)
                    }
                } label: {
                    Text("Join")
                }
                
                TextField("Code or link", text: $inviteCode)
            } message: {
                Text("Enter the server's invite")
            }
            
            Button {
                
            } label: {
                HStack {
                    Image(systemName: "hammer.fill")
                        .resizable()
                        .frame(width: 24, height: 24)

                    Text("Create a new server")
                        .font(.title3)
                }
            }
        }
        .padding(16)
        .presentationDetents([.fraction(0.3)])
    }
}
