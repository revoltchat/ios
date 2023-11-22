//
//  ReversedSrollView.swift
//  Revolt
//
//  Created by Angelo on 15/10/2023.
//

import Foundation
import SwiftUI

func minWidth(in proxy: GeometryProxy, for axis: Axis.Set) -> CGFloat? {
    axis.contains(.horizontal) ? proxy.size.width : nil
}

func minHeight(in proxy: GeometryProxy, for axis: Axis.Set) -> CGFloat? {
    axis.contains(.vertical) ? proxy.size.height : nil
}

struct ReversedScrollView<Content: View>: View {
    var padding: CGFloat? = nil
    @ViewBuilder var builder: (ScrollViewProxy) -> Content

    var body: some View {
        GeometryReader { proxy in
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(alignment: .leading) {
                        Spacer()
                        builder(scrollProxy)
                    }
                    .padding(.horizontal, padding)
                    .frame(
                        minWidth: minWidth(in: proxy, for: .vertical),
                        minHeight: minHeight(in: proxy, for: .vertical)
                    )
                }
            }
        }
    }
}
