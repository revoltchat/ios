//
//  UnreadCounter.swift
//  Revolt
//
//  Created by Angelo on 20/11/2023.
//

import Foundation
import SwiftUI

struct UnreadCounter: View {
    @EnvironmentObject var viewState: ViewState
    var unread: UnreadCount
    
    var body: some View {
        switch unread {
            case .mentions(let count):
                ZStack(alignment: .center) {
                    Circle()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.red)
                    Text("\(count)")
                        .foregroundStyle(.white)
                }
                
            case .unread:
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundStyle(viewState.theme.foreground.color)
        }
    }
}
