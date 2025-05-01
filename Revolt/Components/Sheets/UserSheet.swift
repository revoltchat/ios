//
//  MemberSheet.swift
//  Revolt
//
//  Created by Angelo on 23/10/2023.
//

import Foundation
import SwiftUI
import Flow
import Types
import ExyteGrid

enum Badges: Int, CaseIterable {
    case developer = 1
    case translator = 2
    case supporter = 4
    case responsible_disclosure = 8
    case founder = 16
    case moderation = 32
    case active_supporter = 64
    case paw = 128
    case early_adopter = 256
    case amog = 512
    case amorbus = 1024
}

struct UserSheetHeader: View {
    @EnvironmentObject var viewState: ViewState
    var user: User
    var member: Member?
    var profile: Profile

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let banner = profile.background {
                LazyImage(source: .file(banner), height: 115, clipTo: RoundedRectangle(cornerRadius: 12))
            }
            
            HStack(alignment: .center, spacing: 16) {
                Avatar(user: user, width: 48, height: 48, withPresence: true)

                VStack(alignment: .leading) {
                    if let display_name = user.display_name {
                        Text(display_name)
                            .foregroundStyle(.white)
                            .bold()
                    }
                    
                    Text("\(user.username)")
                        .foregroundStyle(viewState.theme.foreground)
                    + Text("#\(user.discriminator)")
                        .foregroundStyle(viewState.theme.foreground2)
                }
            }
            .padding(.leading, 16)
            .padding(.bottom, 16)
        }
    }
}

struct UserSheet: View {
    @EnvironmentObject var viewState: ViewState
    
    @State var user: User
    @State var member: Member?
    
    @State var profile: Profile?
    @State var owner: User = .init(id: String(repeating: "0", count: 26), username: "Unknown", discriminator: "0000")
    @State var mutualServers: [String] = []
    @State var mutualFriends: [String] = []
    @State var showReportSheet = false
    
    func getRoleColour(role: Role) -> AnyShapeStyle {
        if let colour = role.colour {
            return parseCSSColor(currentTheme: viewState.theme, input: colour)
        } else {
            return AnyShapeStyle(viewState.theme.foreground)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let profile = profile {
                Grid(tracks: 2, flow: .rows, spacing: 12) {
                    UserSheetHeader(user: user, member: member, profile: profile)
                        .gridSpan(column: 2)

                    if let member = member,
                       let server = viewState.servers[member.id.server],
                       let roles = member.roles, !roles.isEmpty
                    {
                        Tile("Roles") {
                            ScrollView {
                                ForEach(roles, id: \.self) { roleId in
                                    let role = server.roles![roleId]!
                                    
                                    HStack {
                                        Text(role.name)
                                        
                                        Spacer()
                                        
                                        Circle()
                                            .foregroundStyle(getRoleColour(role: role))
                                            .frame(width: 16, height: 16)
                                    }
                                }
                            }
                        }
                    }
                    
                    Tile("Joined") { 
                        VStack(alignment: .leading) {
                            Text(createdAt(id: user.id), style: .date)
                            Text("Revolt")
                                .bold()
                        }
                        //.frame(maxWidth: .infinity)
                        
                        if let member {
                            let server = viewState.servers[member.id.server]!
                            let formatter = {
                                let formatter = ISO8601DateFormatter()
                                formatter.formatOptions.insert(.withFractionalSeconds)
                                return formatter
                            }()
                            
                            VStack(alignment: .leading) {
                                Text(formatter.date(from: member.joined_at)!, style: .date)  // TODO
                                Text(verbatim: server.name)
                            }
                            //.frame(maxWidth: .infinity)
                        }
                    }
                    
                    if let badges = user.badges {
                        Tile("Badges") {
                            HFlow {
                                ForEach(Badges.allCases, id: \.self) { value in
                                    Badge(badges: badges, filename: String(describing: value), value: value.rawValue)
                                }
                            }
                        }
                    }
                    
                    if let bot = user.bot {
                        Tile("Owner") {
                            HStack(spacing: 12) {
                                Avatar(user: owner)
                                
                                Text(owner.display_name ?? owner.username)
                            }
                        }
                        .task {
                            if let user = viewState.users[bot.owner] {
                                owner = user
                            } else {
                                Task {
                                    if case .success(let user) = await viewState.http.fetchUser(user: bot.owner) {
                                        owner = user
                                    }
                                }
                            }
                        }
                    }
                    
                    if !mutualFriends.isEmpty {
                        Tile("Mutual Friends") {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(mutualFriends.compactMap { viewState.users[$0] }) { user in
                                        Button {
                                            viewState.openUserSheet(user: user)
                                        } label: {
                                            HStack(spacing: 8) {
                                                Avatar(user: user, width: 16, height: 16, withPresence: true)
                                                
                                                Text(verbatim: user.display_name ?? user.username)
                                                    .lineLimit(1)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    if !mutualServers.isEmpty {
                        Tile("Mutual Servers") {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(mutualServers.compactMap { viewState.servers[$0] }) { server in
                                        Button {
                                            viewState.selectServer(withId: server.id)
                                        } label: {
                                            HStack(spacing: 8) {
                                                ServerIcon(server: server, height: 16, width: 16, clipTo: Circle())
                                                
                                                Text(verbatim: server.name)
                                                    .lineLimit(1)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    if let bio = profile.content {
                        Tile("Bio") {
                            ScrollView {
                                Contents(text: .constant(bio), fontSize: 17)
                            }
                        }
                        .gridSpan(column: 2)
                    }
                    
                    HStack {
                        Group {
                            switch user.relationship ?? .None {
                                case .User:
                                    Button {
                                        viewState.path.append(NavigationDestination.settings)
                                    } label: {
                                        HStack {
                                            Spacer()
                                            
                                            Text("Edit profile")
                                            
                                            Spacer()
                                        }
                                    }
                                    .padding(8)
                                    .background(viewState.theme.accent, in: RoundedRectangle(cornerRadius: 50))
                                    
                                case .Blocked:
                                    EmptyView()  // TODO: unblock
                                case .BlockedOther:
                                    EmptyView()
                                case .Friend:
                                    Button {
                                        Task {
                                            await viewState.openDm(with: user.id)
                                        }
                                    } label: {
                                        HStack {
                                            Spacer()
                                            
                                            Text("Send Message")
                                            
                                            Spacer()
                                        }
                                    }
                                    .padding(8)
                                    .background(viewState.theme.accent, in: RoundedRectangle(cornerRadius: 50))
                                    
                                case .Incoming, .None:
                                    Button {
                                        Task {
                                            await viewState.http.sendFriendRequest(username: user.username)
                                        }
                                    } label: {
                                        HStack {
                                            Spacer()
                                            
                                            Text("Add Friend")
                                            
                                            Spacer()
                                        }
                                    }
                                    .padding(8)
                                    .background(viewState.theme.accent, in: RoundedRectangle(cornerRadius: 50))
                                    
                                case .Outgoing:
                                    Button {
                                        Task {
                                            await viewState.http.removeFriend(user: user.id)
                                        }
                                    } label: {
                                        HStack {
                                            Spacer()
                                            
                                            Text("Cancel Friend Request")
                                            
                                            Spacer()
                                        }
                                    }
                                    .padding(8)
                                    .background(viewState.theme.accent, in: RoundedRectangle(cornerRadius: 50))
                            }
                        }
                        
                        Menu {
                            Button("Block") {
                                Task {
                                    if case .success(let blockedUser) = await viewState.http.blockUser(user: user.id) {
                                        user = blockedUser
                                    }
                                }
                            }
                            
                            Button("Copy ID") {
                                copyText(text: user.id)
                            }
                            
                            Button("Report", role: .destructive) {
                                showReportSheet = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .fontWeight(.light)
                        }
                        .menuStyle(.borderlessButton)
                        .padding(.horizontal, 12)
                    }
                    .gridSpan(column: 2)
                }
                .gridContentMode(.scroll)
                .gridFlow(.rows)
                .gridPacking(.sparse)
                .gridCommonItemsAlignment(.topLeading)
            } else {
                Text("Loading...")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
        .background(viewState.theme.background.color)
        .presentationBackground(viewState.theme.background)
        .sheet(isPresented: $showReportSheet) {
            Text("TODO")
        }
        .task {
            if let profile = user.profile {
                self.profile = profile
            } else {
                profile = try? await viewState.http.fetchProfile(user: user.id).get()
            }
        }
        .task {
            if user.id != viewState.currentUser!.id,
               let mutuals = try? await viewState.http.fetchMutuals(user: user.id).get()
            {
                mutualServers = mutuals.servers
                mutualFriends = mutuals.users
            }
        }
    }
}

struct Badge: View {
    var badges: Int
    var filename: String
    var value: Int
    
    var body: some View {
        if badges & (value << 0) != 0 {
            Image(filename)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        }
    }
}

struct UserSheetPreview: PreviewProvider {
    @StateObject static var viewState: ViewState = ViewState.preview()
        
    static var previews: some View {
        Text("foo")
            .sheet(isPresented: .constant(true)) {
                UserSheet(user: viewState.users["0"]!, member: nil)
            }
            .applyPreviewModifiers(withState: viewState)
    }
}
