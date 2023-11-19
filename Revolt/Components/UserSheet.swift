//
//  MemberSheet.swift
//  Revolt
//
//  Created by Angelo on 23/10/2023.
//

import Foundation
import SwiftUI
import WrappingHStack

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

struct UserSheet: View {
    @EnvironmentObject var viewState: ViewState
    @Binding var user: User
    @Binding var member: Member?
    @State var profile: Profile?

    var body: some View {
        VStack(alignment: .leading) {
            if let profile = profile {
                ZStack {
                    if let banner = profile.background {
                        ZStack {
                            LazyImage(source: .file(banner), height: 100, clipTo: RoundedRectangle(cornerRadius: 10))
                            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                                .frame(height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    
                    HStack(alignment: .center) {
                        Avatar(user: user, width: 48, height: 48, withPresence: true)
                        
                        VStack(alignment: .leading) {
                            if let display_name = user.display_name {
                                Text(display_name)
                                    .foregroundStyle(.white)
                                    .bold()
                            }
                            
                            Text("\(user.username)")
                                .foregroundStyle(.white)
                            + Text("#\(user.discriminator)")
                                .foregroundStyle(.gray)
                        }
                        
                        Spacer()
                        
                        switch user.relationship ?? .None {
                            case .Blocked:
                                EmptyView()  // TODO: unblock
                            case .BlockedOther, .User:
                                EmptyView()
                            case .Friend:
                                Button {
                                    Task {
                                        await viewState.openDm(with: user.id)
                                    }
                                } label: {
                                    Image(systemName: "message.fill")
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                }
                            case .Incoming, .None:
                                Button {
                                    Task {
                                        await viewState.http.sendFriendRequest(username: user.username)
                                    }
                                } label: {
                                    Image(systemName: "person.badge.plus")
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                }
                            case .Outgoing:
                                Button {
                                    Task {
                                        await viewState.http.removeFriend(user: user.id)
                                    }
                                } label: {
                                    Image(systemName: "person.badge.clock")
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                }
                        }
                    }
                    .padding(8)
                }

                if let badges = user.badges {
                    HStack {
                        ForEach(Badges.allCases, id: \.self) { value in
                            Badge(badges: badges, filename: String(describing: value), value: value.rawValue)
                        }
                    }
                }
                
                if let member = member {
                    let server = viewState.servers[member.id.server]!

                    if let roles = member.roles {
                        Text("Roles")
                            .font(.caption)
                        
                        VStack(alignment: .leading) {
                            WrappingHStack(roles, id: \.self, spacing: .constant(8), lineSpacing: 4) { roleId in
                                let role = server.roles![roleId]!
                                
                                Text(role.name)
                                    .padding(8)
                                    .background(RoundedRectangle(cornerRadius: 5).foregroundStyle(.gray))
                            }
                        }
                        
                        //.frame(maxHeight: .infinity)
                    }
                }
                
                if let bio = profile.content {
                    Text("Bio")
                        .font(.caption)
                    
                    Text(bio)
                }
                
                Spacer()
            } else {
                Text("Loading...")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .background(viewState.theme.background.color)
        .presentationDetents([.fraction(0.4), .large])
        .task {
            print(user)
            if let profile = user.profile {
                self.profile = profile
            } else {
                Task {
                    profile = try! await viewState.http.fetchProfile(user: user.id).get()
                }
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
                .frame(width: 24, height: 24)
        }
    }
}

struct UserSheetPreview: PreviewProvider {
    @StateObject static var viewState: ViewState = ViewState.preview()
        
    static var previews: some View {
        UserSheet(user: Binding($viewState.users["0"])!, member: .constant(nil))
            .applyPreviewModifiers(withState: viewState)
    }
}
