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
}

struct LazyImage<S: Shape>: View {
    @EnvironmentObject private var viewState: ViewState

    public var source: Source
    public var height: CGFloat?
    public var width: CGFloat?
    public var clipTo: S

    @ViewBuilder
    var body: some View {
        let url: URL
        
        let _ = switch source {
            case .url(let u):
                url = u
            case .file(let file):
                url = URL(string: viewState.formatUrl(with: file))!
        }
        
        KFImage.url(url)
            .placeholder { Color.clear }
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: width, height: height)
            .clipped()
            .clipShape(clipTo)
    }
}
