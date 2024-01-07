//
//  LazyImage.swift
//  Revolt
//
//  Created by Angelo on 14/10/2023.
//

import Foundation
import SwiftUI
import Kingfisher

enum LazyImageSource {
    case url(URL)
    case file(File)
    case emoji(String)
    case local(Data)
}

struct LazyImage<S: Shape>: View {
    @EnvironmentObject private var viewState: ViewState

    public var source: LazyImageSource
    public var height: CGFloat?
    public var width: CGFloat?
    public var clipTo: S

    var _source: Source {
        switch source {
            case .url(let u):
                return .network(u)
            case .file(let file):
                return .network(URL(string: viewState.formatUrl(with: file))!)
            case .emoji(let id):
                return .network(URL(string: viewState.formatUrl(fromEmoji: id))!)
            case .local(let data):
                return .provider(RawImageDataProvider(data: data, cacheKey: String(data.hashValue)))
        }
    }
    
    @ViewBuilder
    var body: some View {
        KFAnimatedImage.init(source: _source)
            .placeholder { Color.clear }
            .scaledToFit()
            .aspectRatio(contentMode: .fill)
            .frame(width: width, height: height)
            .clipped()
            .clipShape(clipTo)
    }
}
