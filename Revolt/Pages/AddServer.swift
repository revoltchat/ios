//
//  JoinServer.swift
//  Revolt
//
//  Created by Angelo on 01/11/2023.
//

import Foundation
import SwiftUI
import Types

struct AddServer: View {
    @EnvironmentObject var viewState: ViewState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add a server")
                .font(.title)
            
            VStack(alignment: .leading) {
                NavigationLink(destination: JoinServer.init) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.right.square")
                            .resizable()
                            .frame(width: 24, height: 24)
                        
                        Text("Join by invite code or link")
                            .font(.title3)
                    }
                }
                
                NavigationLink(destination: CreateServer.init) {
                    HStack(spacing: 12) {
                        Image(systemName: "hammer.fill")
                            .resizable()
                            .frame(width: 24, height: 24)
                        
                        Text("Create a new server")
                            .font(.title3)
                    }
                }
            }
        }
        .padding(16)
        .background(viewState.theme.background)
    }
}

struct JoinServer: View {
    @EnvironmentObject var viewState: ViewState
    @State var inviteCode: String = ""
    
    var body: some View {
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
    }
}

struct CreateServer: View {
    @EnvironmentObject var viewState: ViewState
    @State var name: String = ""
    
    var body: some View {
        Text("todo")
    }

}

#Preview {
    AddServer()
        .applyPreviewModifiers(withState: ViewState.preview())
}
