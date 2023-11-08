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
    var serverId: String
    
    var body: some View {
        VStack {
            Text("Settings")
        }
        .background(viewState.theme.background.color)
    }
}
