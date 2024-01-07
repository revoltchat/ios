//
//  Avatar.swift
//  Revolt
//
//  Created by Angelo on 14/10/2023.
//

import Foundation
import SwiftUI
import Kingfisher

struct Avatar: View {
    @EnvironmentObject var viewState: ViewState
    
    public var user: User
    public var member: Member? = nil
    public var masquerade: Masquerade? = nil
    public var width: CGFloat = 32
    public var height: CGFloat = 32
    public var withPresence: Bool = false

    var source: LazyImageSource? {
        if let url = masquerade?.avatar {
            return .url(URL(string: url)!)
        } else if let file = member?.avatar ?? user.avatar {
            return .file(file)
        }
        
        return nil
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                Image("Image")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipped()
                    .clipShape(Circle())
            } else {
                if let source = source {
                    LazyImage(source: source, height: height, width: width, clipTo: Circle())
                } else {
                    let baseUrl = viewState.http.baseURL
                    
                    KFImage.url(URL(string: "\(baseUrl)/users/\(user)/default_avatar"))
                        .placeholder { Color.clear }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: height)
                        .clipped()
                        .clipShape(Circle())
                }
            }
            
            if withPresence {
                PresenceIndicator(presence: user.status?.presence, width: width / 2.8, height: height / 2.8)
            }
        }
    }
}

class Avatar_Preview: PreviewProvider {
    static var viewState: ViewState = ViewState.preview()
    
    static var previews: some View {
        Avatar(user: viewState.currentUser!, withPresence: true)
            .environmentObject(viewState)
            .previewLayout(.sizeThatFits)
            .background(Theme.light.background.color)
        
        Avatar(user: viewState.currentUser!, withPresence: true)
            .environmentObject(viewState)
            .previewLayout(.sizeThatFits)
            .background(Theme.dark.background.color)
    }
}
