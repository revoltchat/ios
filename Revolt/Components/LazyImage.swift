//
//  LazyImage.swift
//  Revolt
//
//  Created by Angelo on 14/10/2023.
//

import Foundation
import SwiftUI
import Kingfisher
import Types

enum LazyImageSource {
    case url(URL)
    case file(File)
    case emoji(String)
    case local(Data)
    case id(String, String)
}

struct LazyImage<S: Shape>: View {
    @EnvironmentObject private var viewState: ViewState

    public var source: LazyImageSource
    public var height: CGFloat?
    public var width: CGFloat?
    public var clipTo: S
    public var contentMode: SwiftUI.ContentMode = .fill

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
            case .id(let id, let tag):
                return .network(URL(string: viewState.formatUrl(fromId: id, withTag: tag))!)
        }
    }

    @ViewBuilder
    var body: some View {
        KFAnimatedImage(source: _source)
            .placeholder { Color.clear }
            .aspectRatio(contentMode: contentMode)
            .frame(width: width, height: height)
            .clipped()
            .clipShape(clipTo)
    }
}
