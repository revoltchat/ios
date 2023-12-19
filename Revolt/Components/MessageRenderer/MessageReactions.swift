//
//  MessageReactions.swift
//  Revolt
//
//  Created by Angelo on 05/12/2023.
//

import Foundation
import SwiftUI
import Flow

struct MessageReactions: View {
    @EnvironmentObject var viewState: ViewState
    
    @Binding var reactions: [String: [String]]?
    @Binding var interactions: Interactions?
    
    var body: some View {
        HFlow(spacing: 4) {
            if let reactions = reactions {
                ForEach(Array(reactions), id: \.0) { (emoji, users) in
                    HStack(spacing: 8) {
                        Text(verbatim: "\(users.count)")
                            .font(.footnote)
                            .foregroundStyle(viewState.theme.foreground.color)
                        
                        LazyImage(source: .emoji(emoji), height: 16, width: 16, clipTo: Rectangle())
                            .environmentObject(viewState)
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 5)
                        .fill(viewState.theme.background2)
                        .if(users.contains(viewState.currentUser!.id)) {
                            $0.stroke(viewState.theme.accent)
                        }
                    )
                }
            }
            
            if reactions != nil, interactions != nil {
                Divider()
            }
            
            if let interactions = interactions {
                
            }
        }
    }
}
