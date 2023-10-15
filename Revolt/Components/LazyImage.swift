//
//  LazyImage.swift
//  Revolt
//
//  Created by Angelo on 14/10/2023.
//

import Foundation
import SwiftUI
import Kingfisher


struct LazyImage<S: Shape>: View {
    @EnvironmentObject private var viewState: ViewState

    public var file: File
    public var height: CGFloat?
    public var width: CGFloat?
    public var clipTo: S
    
    @ViewBuilder
    var body: some View {
        KFImage.url(URL(string: viewState.formatUrl(with: file)))
            .placeholder { Color.clear }
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(clipTo)
            .frame(width: width, height: height)
    }
}
