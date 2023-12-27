//
//  LazyImage.swift
//  Revolt
//
//  Created by Angelo on 14/10/2023.
//

import Foundation
import SwiftUI
import Kingfisher

enum Source {
    case url(URL)
    case file(File)
    case emoji(String)
}

struct LazyImage<S: Shape>: View {
    @EnvironmentObject private var viewState: ViewState

    public var source: Source
    public var height: CGFloat?
    public var width: CGFloat?
    public var clipTo: S

    var url: URL {
        switch source {
            case .url(let u):
                return u
            case .file(let file):
                return URL(string: viewState.formatUrl(with: file))!
            case .emoji(let id):
                return URL(string: viewState.formatUrl(fromEmoji: id))!
        }
    }
    
    @ViewBuilder
    var body: some View {
        KFAnimatedImage.url(url)
            .placeholder { Color.clear }
            .scaledToFit()
            .aspectRatio(contentMode: .fill)
            .frame(width: width, height: height)
            .clipped()
            .clipShape(clipTo)
    }
}
