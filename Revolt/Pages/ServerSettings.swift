//
//  ServerSettings.swift
//  Revolt
//
//  Created by Angelo on 08/11/2023.
//

import Foundation
import SwiftUI

struct ServerSettings: View {
    @EnvironmentObject var viewState: ViewState
    @Binding var server: Server
    
    var body: some View {
        VStack {
            Text(verbatim: server.name)
        }
        .background(viewState.theme.background.color)
    }
}
