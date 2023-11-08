//
//  MemberSheet.swift
//  Revolt
//
//  Created by Angelo on 23/10/2023.
//

import Foundation
import SwiftUI
import WrappingHStack

struct UserSheet: View {
    @EnvironmentObject var viewState: ViewState
    @Binding var user: User
    @Binding var member: Member?
    @State var profile: Profile?

    var body: some View {
        VStack(alignment: .leading) {
            if let profile = profile {
                ZStack(alignment: .bottomLeading) {
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
                    }
                    .padding(.bottom, 8)
                    .padding(.leading, 8)
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
