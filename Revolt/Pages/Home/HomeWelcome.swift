//
//  HomeWelcome.swift
//  Revolt
//
//  Created by Angelo on 29/11/2023.
//

import Foundation
import SwiftUI
import Types

struct HomeWelcome: View {
    @Environment(\.openURL) var openURL: OpenURLAction
    @EnvironmentObject var viewState: ViewState
    var toggleSidebar: () -> ()

    var body: some View {
        VStack {
            PageToolbar(toggleSidebar: toggleSidebar) {
                Text("Home")
            }
            
            Spacer()
            
            VStack(alignment: .center, spacing: 24) {
                VStack(alignment: .center, spacing: 8) {
                    Text("Welcome to")
                        .font(.title)
                        .fontWeight(.bold)
                    Image("wide")
                        .maybeColorInvert(color: viewState.theme.background, isDefaultImage: false, defaultIsLight: true)
                }
                
                VStack {
                    Text("The iOS app is current in early beta, plenty of features are unimplemented or buggy, if you want a better experience please use the web app on iOS for now.")
                        .foregroundStyle(viewState.theme.accent)
                        .multilineTextAlignment(.leading)
                        .padding(8)
                }
                .addBorder(viewState.theme.accent, width: 2, cornerRadius: 8)
                .padding(.horizontal, 32)
                
                VStack {
                    HomeButton(title: "Discover Revolt", description: "Find a community based on your hobbies or interests.") {
                        Image(systemName: "safari.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                    } handle: {
                        viewState.path.append(NavigationDestination.discover)
                    }
                    HomeButton(title: "Go to the testers server", description: "You can report issues and discuss improvements with us directly here") {
                        Image(systemName: "arrow.right.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)

                    } handle: {
                        viewState.path.append(NavigationDestination.invite("Testers"))
                    }
                    HomeButton(title: "Donate to Revolt", description: "Support the project by donating - thank you") {
                        Image(systemName: "banknote")
                            .resizable()
                            .frame(width: 32, height: 20)
                    } handle: {
                        openURL(URL(string: "https://wiki.revolt.chat/notes/project/financial-support/")!)
                    }
                    
                    HomeButton(title: "Open Settings", description: "You can also open settings from the bottom of the server list") {
                        Image(systemName: "gearshape.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                    } handle: {
                        viewState.path.append(NavigationDestination.settings)
                    }
                }
            }
            .frame(alignment: .center)
            
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
    HomeWelcome(toggleSidebar: {})
        .applyPreviewModifiers(withState: ViewState.preview())
}
