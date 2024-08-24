//
//  JoinServer.swift
//  Revolt
//
//  Created by Angelo on 01/11/2023.
//

import Foundation
import SwiftUI
import Types

struct AddServerSheet: View {
    @EnvironmentObject var viewState: ViewState
    @Environment(\.dismiss) var dismiss

    @State var showJoinServerAlert: Bool = false
    
    var body: some View {
        NavigationStack {
            HStack {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Add a server")
                        .bold()
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Button {
                            showJoinServerAlert.toggle()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.right.square")
                                    .resizable()
                                    .frame(width: 18, height: 18)
                                
                                Text("Join by invite code or link")
                            }
                        }
                        
                        Button {
                            dismiss()
                            viewState.path.append(NavigationDestination.create_server)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "hammer.fill")
                                    .resizable()
                                    .frame(width: 18, height: 18)
                                
                                Text("Create a new server")
                            }
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding(16)
        .presentationBackground(viewState.theme.background)
        .presentationDetents([.fraction(0.2)])
        .alert("Invite code or link", isPresented: $showJoinServerAlert) {
            JoinServerAlert()
        } message: {
            Text("Enter a link like rvlt.gg/Testers or an invite code like Testers")
        }
    }
}

struct JoinServerAlert: View {
    @EnvironmentObject var viewState: ViewState
    
    @State var text: String = ""
    
    var body: some View {
        TextField("Invite code or link", text: $text)

        Button("Join") {
            Task {
                let join = try! await viewState.http.joinServer(code: text).get()
                viewState.servers[join.server.id] = join.server
                viewState.selectServer(withId: join.server.id)
            }
        }
        
        Button("Cancel", role: .cancel) {}
    }
}

#Preview {
    AddServerSheet()
        .applyPreviewModifiers(withState: ViewState.preview())
}
