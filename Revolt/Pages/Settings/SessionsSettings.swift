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
    
    func deleteSession(session: Session) {
        Task {
            let _ = try! await viewState.http.deleteSession(session: session.id).get()
            sessions = sessions.filter({ $0.id != session.id })
        }
    }

    var body: some View {
        List {
            let currentSession = sessions.first(where: { $0.id == viewState.currentSessionId })

            if let session = currentSession {
                Section("This Device") {
                    SessionView(viewState: viewState, session: session, callback: nil)
                }
                .listRowBackground(viewState.theme.accent.color)

            }
            
            Section("Active Sessions") {
                ForEach($sessions.filter({ $0.id != viewState.currentSessionId }).sorted(by: { $0.id > $1.id })) { session in
                    SessionView(viewState: viewState, session: session.wrappedValue, callback: deleteSession)
                        .swipeActions(edge: .trailing) {
                            Button {
                                deleteSession(session: session.wrappedValue)
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
    @State var browserType: Image?
    @State var showDeletionDialog = false

    var session: Session
    var deleteSessionCallback: ((Session) -> ())?
    var platformType: Image
    var isPlatformTypeSystemImage: Bool // this is a stupid workaround
    var isBrowserTypeSystemImage: Bool // prs welcome.
    
    init(viewState: ViewState, session sess: Session, callback: ( (Session) -> () )?) {
        self._viewState = State(initialValue: viewState)
        self.session = sess
        self.deleteSessionCallback = callback
        isPlatformTypeSystemImage = false
        isBrowserTypeSystemImage = false
        let sessionName = sess.name.lowercased()
        
        if sessionName.contains("ios") {
            platformType = Image(systemName: "iphone.gen3")
            isPlatformTypeSystemImage = true
            browserType = nil
        } else if sessionName.contains("android") {
            platformType = Image(.androidLogo!)
            browserType = nil
        } else if sessionName.contains("on") { // in browser or on desktop
            let types = try? /(?<browser>revolt desktop|[^ ]+) on (?<platform>.+)/.firstMatch(in: sessionName)
            
            if let types = types {
                let platformName = types.output.platform.lowercased()
                
                if platformName.contains("mac os") {
                    platformType = Image(systemName: "apple.logo")
                    isPlatformTypeSystemImage = true
                } else if platformName.contains("windows") {
                    platformType = Image(.windowsLogo!)
                } else {
                    platformType = Image(.linuxLogo!)
                    isPlatformTypeSystemImage = true // dont invert tux cuz he looks evil
                }
                
                let browserName = types.output.browser.lowercased()
                let willSetBrowserType: Image?
                
                if browserName.contains(/chrome|brave|opera|arc/) {
                    willSetBrowserType = Image(.chromeLogo!)
                } else if browserName == "safari" {
                    willSetBrowserType = Image(systemName: "safari")
                    isBrowserTypeSystemImage = true
                } else if browserName == "firefox" {
                    willSetBrowserType = Image(.firefoxLogo!)
                } else if browserName == "revolt desktop" {
                    willSetBrowserType = Image(.monochromeDark!)
                } else {
                    willSetBrowserType = Image(systemName: "questionmark")
                    isPlatformTypeSystemImage = true
                }
                _browserType = State(initialValue: willSetBrowserType)
            } else {
                platformType = Image(systemName: "questionmark.circle")
                _browserType = State(initialValue: nil)
                isPlatformTypeSystemImage = true
            }
        } else {
            platformType = Image(systemName: "questionmark.circle")
            _browserType = State(initialValue: nil)
        }
    }
    
    var body: some View {
        HStack(alignment: .center) {
            ZStack(alignment: .bottomTrailing){
                platformType
                    .resizable()
                    .maybeColorInvert(color: viewState.theme.background2, isDefaultImage: isPlatformTypeSystemImage, defaultIsLight: false)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                
                if browserType != nil {
                    ZStack(alignment: .center) {
                        Circle()
                            .frame(width: 34, height: 34)
                            .foregroundStyle(viewState.theme.background2)
                        browserType!
                            .resizable()
                            .maybeColorInvert(
                                color: viewState.theme.background2,
                                isDefaultImage: isBrowserTypeSystemImage,
                                defaultIsLight: false
                            )
                            .aspectRatio(contentMode: .fit)
                            .foregroundStyle(.black)
                            .frame(height: 28)
                    }
                    .padding(.top, 5)
                }
                 
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
            
            if deleteSessionCallback != nil {
                Spacer()
                Button {
                    showDeletionDialog = true
                } label: {
                    Label("", systemImage: "trash.fill")
                }
            }
        }
        .confirmationDialog("Delete Session?", isPresented: $showDeletionDialog, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                deleteSessionCallback!(session)
            }
        }
    }
}
