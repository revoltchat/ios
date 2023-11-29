//
//  HomeWelcome.swift
//  Revolt
//
//  Created by Angelo on 29/11/2023.
//

import Foundation
import SwiftUI

struct HomeWelcome: View {
    @EnvironmentObject var viewState: ViewState
    @Binding var showSidebar: Bool

    var body: some View {
        VStack {
            PageToolbar(showSidebar: $showSidebar) {
                Text("Home")
            } trailing: {
                EmptyView()
            }
            
            Spacer()
                .frame(maxHeight: 100)
            
            VStack(alignment: .center, spacing: 24) {
                VStack(alignment: .center, spacing: 8) {
                    Text("Welcome to")
                        .font(.title)
                        .fontWeight(.bold)
                    Image("wide")
                }
                
                VStack {
                    HomeButton(title: "Discover Revolt", description: "Find a community based on your hobbies or interests.") {
                        Image(systemName: "safari.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                    } handle: {
                        
                    }
                    HomeButton(title: "Go to the testers server", description: "You can report issues and discuss improvements with us directly here") {
                        Image(systemName: "arrow.right.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)

                    } handle: {
                        
                    }
                    HomeButton(title: "Donate to Revolt", description: "Support the project by donating - thank you") {
                        Image(systemName: "banknote")
                            .resizable()
                            .frame(width: 32, height: 20)
                    } handle: {
                        
                    }
                    
                    HomeButton(title: "Open Settings", description: "You can also open settings from the bottom of the server list") {
                        Image(systemName: "gearshape.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                    } handle: {
                        
                    }
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(viewState.theme.background.color)
    }
}

struct HomeButton<Icon: View>: View {
    @EnvironmentObject var viewState: ViewState
    
    var title: String
    var description: String
    @ViewBuilder var icon: () -> Icon
    var handle: () -> ()
    
    var body: some View {
        Button {
            handle()
        } label: {
            HStack {
                icon()
                    .frame(width: 32, height: 32)
                    .padding(8)
                
                VStack(alignment: .leading) {
                    Text(title)
                    Text(description)
                        .font(.caption2)
                        .foregroundStyle(viewState.theme.foreground2.color)
                        .lineLimit(5)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity)
                
                Image(systemName: "chevron.right")
                    .padding(8)
            }
            .padding(.horizontal, 8)
        }
        .frame(width: 300, height: 80)
        .background(viewState.theme.background2.color)
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

#Preview {
    HomeWelcome(showSidebar: .constant(false))
        .applyPreviewModifiers(withState: ViewState.preview())
}
