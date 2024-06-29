//
//  CheckboxStyle.swift
//  Revolt
//
//  Created by Angelo on 19/06/2024.
//

import SwiftUI

struct CheckboxStyle: ToggleStyle {
    @EnvironmentObject var viewState: ViewState
    
    func makeBody(configuration: Self.Configuration) -> some View {
        return HStack {
            configuration.label
            
            Spacer()
            
            if configuration.isOn {
                Image(systemName: "checkmark")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundColor(viewState.theme.accent.color)
            }
            
        }
        .onTapGesture { configuration.isOn.toggle() }
    }
}
