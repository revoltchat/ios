//
//  ServerIcon.swift
//  Revolt
//
//  Created by Angelo on 31/10/2023.
//

import Foundation
import SwiftUI


struct ServerIcon: View {
    var server: Server
    var height: CGFloat? = nil
    var width: CGFloat? = nil
    
    var body: some View {
        if let icon = server.icon {
            LazyImage(source: .file(icon), height: height, width: height, clipTo: Circle())
        } else {
            ZStack(alignment: .center) {
                let firstChar = server.name.first!
                
                Circle()
                    .fill(.gray)  // TODO: background3
                    .frame(width: width, height: height)

                Text(verbatim: "\(firstChar)")
            }
        }
    }
}


struct ServerListIcon: View {
    var server: Server
    var height: CGFloat? = nil
    var width: CGFloat? = nil
    
    @Binding var currentSelection: MainSelection?
    
    var body: some View {
        if let icon = server.icon {
            if currentSelection == .server(server.id) {
                LazyImage(source: .file(icon), height: height, width: height, clipTo: Rectangle())
            } else {
                LazyImage(source: .file(icon), height: height, width: height, clipTo: Circle())
            }
        } else {
            ZStack(alignment: .center) {
                let firstChar = server.name.first!
                
                Circle()
                    .fill(.gray)  // TODO: background3
                    .frame(width: width, height: height)

                Text(verbatim: "\(firstChar)")
            }
        }
    }
}
