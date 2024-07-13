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
    @Binding var showSidebar: Bool
    @ViewBuilder var contents: () -> C
    @ViewBuilder var trailing: () -> T
    
    var body: some View {
        ZStack {
            HStack(alignment: .center) {
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
                
                trailing()
            }
            
            HStack(alignment: .center) {
                Spacer()
                
                contents()
                
                Spacer()
            }
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

#Preview {
    PageToolbar(showSidebar: .constant(false)) {
        Text("Placeholder")
    } trailing: {
        Text("Ending")
    }
    .applyPreviewModifiers(withState: ViewState.preview())
}
