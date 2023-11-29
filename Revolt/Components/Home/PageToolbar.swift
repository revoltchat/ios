//
//  PageToolbar.swift
//  Revolt
//
//  Created by Angelo on 27/11/2023.
//

import Foundation
import SwiftUI

struct PageToolbar<C: View, T: View>: View {
    @EnvironmentObject var viewState: ViewState
    @Binding var showSidebar: Bool
    @ViewBuilder var contents: () -> C
    @ViewBuilder var trailing: () -> T
    
    var body: some View {
        HStack {
            Button {
                withAnimation {
                    showSidebar = true
                }
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
        .padding(.vertical, 8)
        .background(viewState.theme.topBar.color)
    }
}

#Preview {
    PageToolbar(showSidebar: .constant(false)) {
        Text("Placeholder")
    } trailing: {
        Text("Ending")
    }
    .applyPreviewModifiers(withState: ViewState.preview())
}
