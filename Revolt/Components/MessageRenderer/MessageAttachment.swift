//
//  MessageAttachment.swift
//  Revolt
//
//  Created by Angelo on 31/10/2023.
//

import Foundation
import SwiftUI
import AVKit
import Types

var fmt = ByteCountFormatter()

struct MessageAttachment: View {
    @EnvironmentObject var viewState: ViewState
    var attachment: File
    
        
    var body: some View {
        switch attachment.metadata {
            case .image(_):
                LazyImage(source: .file(attachment), clipTo: RoundedRectangle(cornerRadius: 5))
                    .aspectRatio(contentMode: .fit)

            case .video(_):
                VideoPlayer(player: AVPlayer(url: URL(string: viewState.formatUrl(with: attachment))!))
                    .aspectRatio(contentMode: .fit)

            case .file(_), .text(_), .audio(_):
                HStack(alignment: .center) {
                    Image(systemName: "doc")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    
                    VStack(alignment: .leading) {
                        Text(attachment.filename)
                        Text(fmt.string(fromByteCount: attachment.size))
                            .font(.caption)
                    }
                    .padding(.vertical, 8)
                    
                    Spacer()
                    
                    Button {
                        print("todo")
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .padding(.trailing, 16)
                    .padding(.vertical, 8)
                }
                .background(viewState.theme.background2.color)
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
    }
}
