//
//  PageToolbar.swift
//  Revolt
//
//  Created by Angelo on 27/11/2023.
//

import Foundation
import SwiftUI
import Types

struct PageToolbar<C: View, T: View>: View {
    @EnvironmentObject var viewState: ViewState
    var toggleSidebar: () -> ()
    
    var contents: () -> C
    var trailing: (() -> T)
    
    init(toggleSidebar: @escaping () -> (), @ViewBuilder contents: @escaping () -> C, @ViewBuilder trailing: @escaping () -> T) {
        self.toggleSidebar = toggleSidebar
        self.contents = contents
        self.trailing = trailing
    }
    
    var body: some View {
        HStack(alignment: .center) {
            Button {
                toggleSidebar()
            } label: {
                Image(systemName: "line.3.horizontal")
                    .resizable()
                    .frame(width: 24, height: 14)
                    .foregroundStyle(viewState.theme.foreground2.color)
            }
            
            Spacer()
            
            contents()
            
            Spacer()
            
            trailing()
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
        .padding(.bottom, 8)
        .background(viewState.theme.topBar.color)
        .overlay(alignment: .bottom) {
            Rectangle()
                .frame(maxWidth: .infinity, maxHeight: 1)
                .foregroundStyle(viewState.theme.background2)
        }
    }
}

extension PageToolbar where T == EmptyView {
    init(toggleSidebar: @escaping () -> (), @ViewBuilder contents: @escaping () -> C) {
        self.toggleSidebar = toggleSidebar
        self.contents = contents
        self.trailing = { EmptyView() }
    }
}

#Preview {
    
    PageToolbar(toggleSidebar: {}) {
        Text("Placeholder")
    } trailing: {
        Text("Ending")
    }
    .applyPreviewModifiers(withState: ViewState.preview())
}
