//
//  SessionsSettings.swift
//  Revolt
//
//  Created by Angelo on 31/10/2023.
//

import Foundation
import SwiftUI

struct SessionsSettings: View {
    @EnvironmentObject var viewState: ViewState
    @State var sessions: [Session] = []

    var body: some View {
        List {
            let currentSession = sessions.first(where: { $0.id == viewState.currentSessionId })

            if let session = currentSession {
                Section("This Device") {
                    SessionView(session: session)
                }
                .listRowBackground(viewState.theme.accent.color)

            }
            
            Section("Active Sessions") {
                ForEach($sessions.filter({ $0.id != viewState.currentSessionId }).sorted(by: { $0.id > $1.id })) { session in
                    SessionView(session: session.wrappedValue)
                }
            }
            .listRowBackground(viewState.theme.background2.color)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(viewState.theme.background.color)
        .task {
            sessions = try! await viewState.http.fetchSessions().get()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Sessions")
            }
        }
        .toolbarBackground(viewState.theme.topBar.color, for: .automatic)
    }
}

struct SessionView: View {
    @EnvironmentObject var viewState: ViewState
    var session: Session
    
    func delete() {
        
    }
    
    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: "lock")
                .resizable()
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading) {
                Text(session.name)
                let created = createdAt(id: session.id)
                let days = Calendar.current.dateComponents([.day], from: created, to: Date.now).day!
                
                if days == 0 {
                    Text("Created today")
                } else {
                    Text("Created \(days) days ago")
                }
            }
            .padding(.leading, 16)
            .padding(.vertical, 8)
        }
        .swipeActions(edge: .trailing) {
            Button(action: delete, label: {
                Label("Delete", systemImage: "trash.fill")
            })
            .tint(.red)
        }
    }
}
