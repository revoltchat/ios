//
//  Discovery.swift
//  Revolt
//
//  Created by Angelo on 18/11/2023.
//

import Foundation
import SwiftUI
import WebKit
import Types

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
        let css = """
            :root {
                --accent: \(viewState.theme.accent.hex)!important;
                --background: \(viewState.theme.background.hex)!important;
                --primary-background: \(viewState.theme.background2.hex)!important;
                --secondary-background: \(viewState.theme.background3.hex)!important;
                --tertiary-background: \(viewState.theme.background4.hex)!important;
                --foreground: \(viewState.theme.foreground.hex)!important;
                --secondary-foreground: \(viewState.theme.foreground2.hex)!important;
                --tertiary-foreground: \(viewState.theme.foreground3.hex)!important;
            }
        """
        
        let js = """
            var style = document.createElement("style");
            style.innerHTML = `\(css)`;
            document.head.appendChild(style);
        """
        
        let script = WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let controller = WKUserContentController()
        controller.addUserScript(script)
        
        let config = WKWebViewConfiguration()
        config.userContentController = controller
        
        let view = WKWebView(frame: .zero, configuration: config)
        view.backgroundColor = .init(viewState.theme.background.color)
        view.underPageBackgroundColor = .init(viewState.theme.background.color)

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
