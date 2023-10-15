//
//  Avatar.swift
//  Revolt
//
//  Created by Angelo on 14/10/2023.
//

import Foundation
import SwiftUI

struct Avatar: View {
    @EnvironmentObject var viewState: ViewState
    
    public var user: User
    public var width: CGFloat = 32
    public var height: CGFloat = 32

    var body: some View {
        if let avatar = user.avatar {
            LazyImage(file: avatar, height: height, width: width, clipTo: Circle())
        } else {
            let baseUrl = viewState.http.baseURL

            AsyncImage(url: URL(string: "\(baseUrl)/users/\(user)/default_avatar")) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .clipShape(Circle())
                        .frame(width: width, height: height)
                } else {
                    Color.clear
                        .clipShape(Circle())
                        .frame(width: width, height: height)
                }
            }
        }
    }
}
