//
//  AppearanceSettings.swift
//  Revolt
//
//  Created by Angelo on 31/10/2023.
//

import Foundation
import SwiftUI


struct ThemeColorPicker: View {
    @Environment(\.self) var environment
    @EnvironmentObject var viewState: ViewState
    
    var title: String
    @Binding var color: ThemeColor
    
    var body: some View {
        ColorPicker(selection: Binding {
            color.color
        } set: { new in
            color.set(with: new.resolve(in: environment))
        }, label: {
            Text(title)
        })
    }
}

struct AppearanceSettings: View {
    @Environment(\.self) var environment
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewState: ViewState

    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 4) {
                Button {
                    viewState.theme = .light
                } label: {
                    Text("Light")
                        .foregroundStyle(viewState.theme.accent.color)
                }
                .frame(maxWidth: .infinity)
                
                Button {
                    viewState.theme = .dark
                } label: {
                    Text("Dark")
                        .foregroundStyle(viewState.theme.accent.color)
                }
                .frame(maxWidth: .infinity)
                
                Button {
                    let _ = viewState.applySystemScheme(theme: colorScheme, followSystem: true)
                } label: {
                    Text("Auto")
                        .foregroundStyle(viewState.theme.accent.color)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)

            ThemeColorPicker(title: "Accent", color: $viewState.theme.accent)
            ThemeColorPicker(title: "Background", color: $viewState.theme.background)
            ThemeColorPicker(title: "Primary Background", color: $viewState.theme.background2)
            ThemeColorPicker(title: "Secondary Background", color: $viewState.theme.background3)
            ThemeColorPicker(title: "Tertiary Background", color: $viewState.theme.background4)
            ThemeColorPicker(title: "Foreground", color: $viewState.theme.foreground)
            ThemeColorPicker(title: "Secondary Foreground", color: $viewState.theme.foreground2)
            ThemeColorPicker(title: "Tertiary Foreground", color: $viewState.theme.foreground3)
            ThemeColorPicker(title: "Message Box", color: $viewState.theme.messageBox)
            ThemeColorPicker(title: "Navigation Bar", color: $viewState.theme.topBar)
            ThemeColorPicker(title: "Error", color: $viewState.theme.error)
            ThemeColorPicker(title: "Mention", color: $viewState.theme.mention)
            
            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Appearance")
            }
        }
        .toolbarBackground(viewState.theme.topBar, for: .automatic)
        .padding(.horizontal, 16)
        .background(viewState.theme.background)
        .animation(.easeInOut, value: viewState.theme)
        .frame(maxHeight: .infinity)
    }
}

struct AppearanceSettings_Preview: PreviewProvider {
    static var previews: some View {
        let viewState = ViewState.preview()
        
        AppearanceSettings()
        .applyPreviewModifiers(withState: viewState.applySystemScheme(theme: .light))
        
        AppearanceSettings()
        .applyPreviewModifiers(withState: viewState.applySystemScheme(theme: .dark))
    }
}
