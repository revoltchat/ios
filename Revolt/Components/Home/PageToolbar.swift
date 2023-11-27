//
//  PageToolbar.swift
//  Revolt
//
//  Created by Angelo on 27/11/2023.
//

import Foundation
import SwiftUI

struct PageToolbar<C: View>: View {
    @EnvironmentObject var viewState: ViewState
    @Binding var showSidebar: Bool
    @ViewBuilder var contents: () -> C
    
    var body: some View {
        HStack {
            Button {
                withAnimation {
                    showSidebar = true
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .frame(width: 24, height: 24)
            }
            
            Spacer()
            
            contents()
            
            Spacer()
        }
        .padding(.horizontal, 8)
    }
}
