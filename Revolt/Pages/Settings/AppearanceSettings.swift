//
//  AppearanceSettings.swift
//  Revolt
//
//  Created by Angelo on 31/10/2023.
//

import Foundation
import SwiftUI


struct AppearanceSettings: View {
    @Environment(\.self) var environment
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewState: ViewState

    @State var accent: Color
    @State var background: Color
    @State var background2: Color
    @State var textColor: Color
    @State var messageBox: Color
    @State var messageBoxBackground: Color
    @State var topBar: Color
    @State var messageBoxBorder: Color

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

            ColorPicker(selection: $accent, label: {
                Text("Accent")
            })
            .onChange(of: accent) {
                let resolved = accent.resolve(in: environment)
                viewState.theme.accent.set(with: resolved)
            }
            
            ColorPicker(selection: $background, label: {
                Text("Primary Background")
            })
            .onChange(of: background) {
                let resolved = background.resolve(in: environment)
                viewState.theme.background.set(with: resolved)
            }
            
            ColorPicker(selection: $background2, label: {
                Text("Secondary Background")
            })
            .onChange(of: background2) {
                let resolved = background2.resolve(in: environment)
                viewState.theme.background2.set(with: resolved)
            }
            
            ColorPicker(selection: $textColor, label: {
                Text("Text Colour")
            })
            .onChange(of: textColor) {
                let resolved = textColor.resolve(in: environment)
                viewState.theme.foreground.set(with: resolved)
            }
            
            ColorPicker(selection: $messageBox, label: {
                Text("Message Box")
            })
            .onChange(of: messageBox) {
                let resolved = messageBox.resolve(in: environment)
                viewState.theme.messageBox.set(with: resolved)
            }
            
            ColorPicker(selection: $messageBoxBackground, label: {
                Text("Message Box Background")
            })
            .onChange(of: messageBoxBackground) {
                let resolved = messageBoxBackground.resolve(in: environment)
                viewState.theme.messageBoxBackground.set(with: resolved)
            }
            
            ColorPicker(selection: $messageBoxBorder, label: {
                Text("Message Box Border")
            })
            .onChange(of: messageBoxBorder) {
                let resolved = messageBoxBorder.resolve(in: environment)
                viewState.theme.messageBoxBorder.set(with: resolved)
            }
            
            ColorPicker(selection: $topBar, label: {
                Text("Top Bar")
            })
            .onChange(of: topBar) {
                let resolved = topBar.resolve(in: environment)
                viewState.theme.topBar.set(with: resolved)
            }
            
            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Appearance")
            }
        }
        .toolbarBackground(viewState.theme.topBar.color, for: .automatic)

        .padding(.horizontal, 16)
        .background(viewState.theme.background.color)
        .animation(.easeInOut, value: viewState.theme)
    }
}

struct AppearanceSettings_Preview: PreviewProvider {
    static var previews: some View {
        let viewState = ViewState.preview()
        AppearanceSettings(
            accent: viewState.theme.accent.color,
            background: viewState.theme.background.color,
            background2: viewState.theme.background2.color,
            textColor: viewState.theme.foreground.color,
            messageBox: viewState.theme.messageBox.color,
            messageBoxBackground: viewState.theme.messageBoxBackground.color,
            topBar: viewState.theme.topBar.color,
            messageBoxBorder: viewState.theme.messageBoxBorder.color
        )
        .applyPreviewModifiers(withState: viewState.applySystemScheme(theme: .light))
        
        AppearanceSettings(
            accent: viewState.theme.accent.color,
            background: viewState.theme.background.color,
            background2: viewState.theme.background2.color,
            textColor: viewState.theme.foreground.color,
            messageBox: viewState.theme.messageBox.color,
            messageBoxBackground: viewState.theme.messageBoxBackground.color,
            topBar: viewState.theme.topBar.color,
            messageBoxBorder: viewState.theme.messageBoxBorder.color
        )
        .applyPreviewModifiers(withState: viewState.applySystemScheme(theme: .dark))
    }
}
