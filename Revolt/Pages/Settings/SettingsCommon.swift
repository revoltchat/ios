//
//  SettingsCommon.swift
//  Revolt
//
//  Created by Angelo on 2024-02-10.
//

import SwiftUI

fileprivate struct SettingsFieldTextField: View {
    var body: some View {
        Text("Text Field")
    }
}

struct SettingFieldNavigationItem: View {
    @EnvironmentObject var viewState: ViewState
    
    @State var includeValueIfAvailable: Bool

    var body: some View {
        Text("Hello, World!")
    }
}

struct SettingsSheetContainer<Content: View>: View {
    @EnvironmentObject var viewState: ViewState
    
    @Binding var showSheet: Bool
    @ViewBuilder var sheet: () -> Content
    
    var body: some View {
        NavigationView {
            sheet()
                .padding()
                .backgroundStyle(viewState.theme.background)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            showSheet = false
                        } label: {
                            Text("Cancel")
                        }
                    }
                }
        }
    }
}

struct MaybeDismissableSettingsSheetContainer<Content: View>: View {
    @EnvironmentObject var viewState: ViewState
    
    @Binding var showSheet: Bool
    @Binding var sheetDismissDisabled: Bool
    @ViewBuilder var sheet: () -> Content
    
    var body: some View {
        NavigationView {
            sheet()
                .padding()
                .backgroundStyle(viewState.theme.background)
                .interactiveDismissDisabled(sheetDismissDisabled)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            showSheet = false
                        } label: {
                            Text("Cancel")
                        }
                    }
                }
        }
    }
}
