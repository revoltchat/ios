//
//  Discovery.swift
//  Revolt
//
//  Created by Angelo on 18/11/2023.
//

import Foundation
import SwiftUI
import WebKit

#if os(macOS)

struct WebView: NSViewRepresentable {
    @EnvironmentObject var viewState: ViewState
    
    let url: URL
    
    func makeNSView(context: Context) -> WKWebView {
        let view = WKWebView()
        // view.backgroundColor = .init(viewState.theme.background.color)
        
        return view
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }

}

#else
struct WebView: UIViewRepresentable {
    @EnvironmentObject var viewState: ViewState

    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView()
        view.backgroundColor = .init(viewState.theme.background.color)

        return view
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
#endif

struct Discovery: View {
    @EnvironmentObject var viewState: ViewState

    var body: some View {
        WebView(url: URL(string: "https://rvlt.gg/discover?embedded=true")!)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: "safari.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                        
                        Text("Discovery")
                    }
                }
            }
            .background(viewState.theme.background.color)
            .toolbarBackground(viewState.theme.topBar.color, for: .automatic)
    }
}
