//
//  PermissionToggle.swift
//  Revolt
//
//  Created by Angelo on 25/09/2024.
//

import Foundation
import SwiftUI


struct PermissionToggle<Label: View>: View {
    @Binding var value: Bool?
    @ViewBuilder var label: () -> Label
    
    var body: some View {
        HStack {
            label()
            
            Spacer()
            
            Picker("select permission", selection: $value) {
                Image(systemName: "xmark")
                    .foregroundStyle(.red)
                    .tag(Optional.some(false))
                
                Image(systemName: "square")
                    .tag(nil as Bool?)
                
                Image(systemName: "checkmark")
                    .foregroundStyle(.green)
                    .tag(Optional.some(true))
            }
            .tint(value == true ? .green : value == false ? .red : nil)
            .pickerStyle(.segmented)
            .fixedSize()
        }
    }
}
