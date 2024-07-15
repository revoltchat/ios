//
//  SessionsSettings.swift
//  Revolt
//
//  Created by Angelo on 31/10/2023.
//

import Foundation
import SwiftUI
import Types

struct SessionsSettings: View {
    @EnvironmentObject var viewState: ViewState
    @State var sessions: [Session] = []

    var body: some View {
        List {
            let currentSession = sessions.first(where: { $0.id == viewState.currentSessionId })

            if let session = currentSession {
                Section("This Device") {
                    SessionView(viewState: viewState, session: session)
                }
                .listRowBackground(viewState.theme.accent.color)

            }
            
            Section("Active Sessions") {
                ForEach($sessions.filter({ $0.id != viewState.currentSessionId }).sorted(by: { $0.id > $1.id })) { session in
                    SessionView(viewState: viewState, session: session.wrappedValue)
                        .swipeActions(edge: .trailing) {
                            Button {
                                Task {
                                    let _ = try! await viewState.http.deleteSession(session: session.id).get()
                                    sessions = sessions.filter({ $0.id != session.id })
                                }
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                            .tint(.red)
                        }
                }
            }
            .listRowBackground(viewState.theme.background2.color)
        }
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
    @State var viewState: ViewState
    var session: Session
    var browserType: Image?
    var platformType: Image
    
    init(viewState: ViewState, session sess: Session) {
        self._viewState = State(initialValue: viewState)
        self.session = sess
        let sessionName = sess.name.lowercased()
        
        if sessionName.contains("ios") {
            platformType = Image(systemName: "iphone.gen3")
            browserType = nil
        } else if sessionName.contains("android") {
            platformType = Image(.androidLogo!)
            browserType = nil
        } else if sessionName.contains("on") { // in browser or on desktop
            let types = try? /(?<browser>revolt desktop|[^ ]+) on (?<platform>.+)/.firstMatch(in: sessionName)
            
            if let types = types {
                let platformName = types.output.platform.lowercased()
                
                if platformName == "mac os" {
                    platformType = Image(systemName: "apple.logo")
                } else if platformName == "windows" {
                    platformType = Image(.windowsLogo!)
                } else {
                    platformType = Image(.linuxLogo!)
                }
                
                let browserName = types.output.browser.lowercased()
                
                if browserName.contains(/chrome|brave|opera|arc/) {
                    browserType = Image(.chromeLogo!)
                } else if browserName == "safari" {
                    browserType = Image(systemName: "safari")
                } else if browserName == "firefox" {
                    browserType = Image(.firefoxLogo!)
                } else if browserName == "revolt desktop" {
                    browserType = Image(.monochrome!)
                } else {
                    browserType = Image(systemName: "questionmark")
                }
            } else {
                platformType = Image(systemName: "questionmark.circle")
                browserType = nil
            }
        } else {
            platformType = Image(systemName: "questionmark.circle")
            browserType = nil
        }
    }
    
    var body: some View {
        HStack(alignment: .center) {
            ZStack {
                platformType
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                /*
                if browserType != nil {
                    browserType!
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(.black)
                        //.padding(.leading, 20)
                        //.padding(.top, 20)
                        .frame(height: 32, alignment: .bottomTrailing) // TODO: unfuck this positioning
                }
                 */
            }
            VStack(alignment: .leading) {
                Text(session.name)
                    .bold()
                let created = createdAt(id: session.id)
                let days = Calendar.current.dateComponents([.day], from: created, to: Date.now).day!
                
                if days == 0 {
                    Text("Created today")
                } else {
                    Text("Created \(days) day(s) ago")
                }
            }
            .padding(.leading, 16)
            .padding(.vertical, 8)
        }
    }
}
