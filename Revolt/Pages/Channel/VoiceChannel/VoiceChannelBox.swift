//
//  VoiceChannelBox.swift
//  Revolt
//
//  Created by Angelo on 27/01/2025.
//

import SwiftUI

struct VoiceChannelBox<Title: View, Contents: View, Trailing: View, Overlay: View>: View {
    @EnvironmentObject var viewState: ViewState
    
    var title: Title
    var contents: Contents
    var trailing: Trailing?
    var overlay: Overlay?
    
    @State var selected: Bool = false
    
    init(@ViewBuilder title: () -> Title, @ViewBuilder contents: () -> Contents, @ViewBuilder trailing: () -> Trailing, @ViewBuilder overlay: () -> Overlay) {
        self.title = title()
        self.contents = contents()
        self.trailing = trailing()
        self.overlay = overlay()
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            HStack(alignment: .center) {
                Spacer()
                VStack(alignment: .center) {
                    Spacer()
                    contents
                    Spacer()
                }
                Spacer()
            }
            .zIndex(0)
            
            HStack {
                title
                Spacer()
                
                if let trailing {
                    trailing
                }
            }
            .frame(alignment: .bottom)
            .zIndex(1)
            
            
            if selected {
                overlay
                    .frame(alignment: .topLeading)
                    .zIndex(2)
            }
        }
        .aspectRatio(16/9, contentMode: .fill)
        .padding(8)
        .background(viewState.theme.background2)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture { withAnimation { selected.toggle() } }
    }
}

extension VoiceChannelBox where Title == Text {
    init(
        title: String,
        @ViewBuilder contents: @escaping () -> Contents,
        @ViewBuilder trailing: @escaping () -> Trailing,
        @ViewBuilder overlay: @escaping () -> Overlay
    ) {
        self.title = Text(title)
        self.contents = contents()
        self.trailing = trailing()
        self.overlay = overlay()
    }
    
    init(
        title: String,
        @ViewBuilder contents: @escaping () -> Contents,
        @ViewBuilder trailing: @escaping () -> Trailing
    )
        where Overlay == EmptyView
    {
        self.title = Text(title)
        self.contents = contents()
        self.trailing = trailing()
        self.overlay = nil
    }
    
    init(
        title: String,
        @ViewBuilder contents: @escaping () -> Contents,
        @ViewBuilder overlay: @escaping () -> Overlay
    )
        where Trailing == EmptyView
    {
        self.title = Text(title)
        self.contents = contents()
        self.trailing = nil
        self.overlay = overlay()
    }
    
    init(
        title: String, @ViewBuilder
        contents: @escaping () -> Contents
    )
        where Trailing == EmptyView,
              Overlay == EmptyView
    {
        self.title = Text(title)
        self.contents = contents()
        self.trailing = nil
        self.overlay = nil
    }
}

extension VoiceChannelBox where Trailing == EmptyView {
    init(
        @ViewBuilder title: () -> Title,
        @ViewBuilder contents: () -> Contents,
        @ViewBuilder overlay: () -> Overlay
    ) {
        self.title = title()
        self.contents = contents()
        self.trailing =  nil
        self.overlay = overlay()
    }
}
