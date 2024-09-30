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
            withAnimation {
                color.set(with: new.resolve(in: environment))
            }
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
        VStack {
            HStack {
                Spacer()
                
                Button {
                    withAnimation {
                        viewState.theme = .light
                    }
                } label: {
                    Text("Light")
                        .foregroundStyle(viewState.theme.accent.color)
                }
                
                Spacer()
                
                Button {
                    withAnimation {
                        viewState.theme = .dark
                    }
                } label: {
                    Text("Dark")
                        .foregroundStyle(viewState.theme.accent.color)
                }
                
                Spacer()
                
                Button {
                    withAnimation {
                        let _ = viewState.applySystemScheme(theme: colorScheme, followSystem: true)
                    }
                } label: {
                    Text("Auto")
                        .foregroundStyle(viewState.theme.accent.color)
                }
                
                Spacer()
            }
            .padding([.horizontal, .top], 16)
            
            List {
                Section("Theme") {
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
                }
                .listRowBackground(viewState.theme.background2)
                .animation(.easeInOut, value: viewState.theme)

                
                Section("Messages") {
                    CheckboxListItem(title: "Compact Mode", isOn: Binding(get: { false }, set: {_ in }))
                        .listRowBackground(viewState.theme.background2)
                        .animation(.easeInOut, value: viewState.theme)
                }
                
            }
            .scrollContentBackground(.hidden)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Appearance")
            }
        }
        .background(viewState.theme.background)
        .toolbarBackground(viewState.theme.topBar, for: .automatic)
        .animation(.easeInOut, value: viewState.theme)
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
