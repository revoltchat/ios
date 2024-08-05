//
//  ServerIcon.swift
//  Revolt
//
//  Created by Angelo on 31/10/2023.
//

import Foundation
import SwiftUI
import Types


struct ServerIcon<S: Shape>: View {
    @EnvironmentObject var viewState: ViewState
    
    var server: Server
    var height: CGFloat? = nil
    var width: CGFloat? = nil
    var clipTo: S
    
    var body: some View {
        if let icon = server.icon {
            LazyImage(source: .file(icon), height: height, width: height, clipTo: clipTo)
        } else {
            ZStack(alignment: .center) {
                let firstChar = server.name.first ?? "?"
                
                clipTo
                    .fill(viewState.theme.background3)  // TODO: background3
                    .frame(width: width, height: height)

                Text(verbatim: "\(firstChar)")
                    .bold()
            }
        }
    }
}


struct ServerListIcon: View {
    @EnvironmentObject var viewState: ViewState
    
    var server: Server
    var height: CGFloat? = nil
    var width: CGFloat? = nil
    
    @Binding var currentSelection: MainSelection
    
    var body: some View {
        ServerIcon(
            server: server,
            height: height,
            width: width,
            clipTo: RoundedRectangle(cornerRadius: currentSelection == .server(server.id) ? 12 : 100)
        )
            .animation(.easeInOut, value: currentSelection == .server(server.id))
    }
}
