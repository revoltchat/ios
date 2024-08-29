//
//  TileGrid.swift
//  Revolt
//
//  Created by Angelo on 29/08/2024.
//

import Foundation
import SwiftUI
import ExyteGrid

struct Tile<Body: View>: View {
    @EnvironmentObject var viewState: ViewState
    
    var title: String
    var content: () -> Body
    
    @State var showPopout: Bool = false
    
    init(
        _ title: String,
        @ViewBuilder content: @escaping () -> Body
    ) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .bold()
                    .font(.title)
            
                HStack {
                    VStack(alignment: .leading) {
                        content()
                    }
                    
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 160)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .background(viewState.theme.background2, in: RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            showPopout.toggle()
        }
        .sheet(isPresented: $showPopout) {
            ScrollView {
                VStack(alignment: .leading) {
                    Text(title)
                        .bold()
                        .font(.title)
                    
                    Group {
                        content()
                    }
                }
            }
            .padding(.horizontal, 16)
            .presentationDetents([.medium])
            .presentationBackground(viewState.theme.background)
        }
    }
}
