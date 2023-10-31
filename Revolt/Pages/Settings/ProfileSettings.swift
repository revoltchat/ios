//
//  ProfileSettings.swift
//  Revolt
//
//  Created by Angelo on 31/10/2023.
//

import Foundation
import SwiftUI

struct ProfileSettings: View {
    @EnvironmentObject var viewState: ViewState
    @State var profile: Profile? = nil

    var body: some View {
        VStack(alignment: .leading) {
            let user = viewState.currentUser!

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
            }
            
            Group {
                Text("Profile Picture")
                Avatar(user: user, width: 56, height: 56)
            }
            
            Group {
                if let banner = profile?.background {
                    Text("Banner")
                    LazyImage(source: .file(banner), height: 100, clipTo: RoundedRectangle(cornerRadius: 10))
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .background(viewState.theme.background.color)
        .task {
            profile = viewState.currentUser?.profile
            
            if profile == nil {
                profile = try! await viewState.http.fetchProfile(user: viewState.currentUser!.id).get()
            }
        }
    }
}
