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

fileprivate struct WebView: NSViewRepresentable {
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
fileprivate struct WebView: UIViewRepresentable {
    @EnvironmentObject var viewState: ViewState

    let url: URL

    class Delegate: NSObject, WKScriptMessageHandler {
        var viewState: ViewState
        
        init(viewState: ViewState) {
            self.viewState = viewState
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "serverInviteClicked", let id = message.body as? String {
                viewState.path.append(NavigationDestination.invite(id))
            }
        }
                
//        func webView(
//            _ webView: WKWebView,
//            decidePolicyFor navigationAction: WKNavigationAction,
//            decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void
//        ) {
//            print(navigationAction)
//            if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url, url.host() == "app.revolt.chat" {
//                decisionHandler(.cancel)
//                viewState.path.append(NavigationDestination.invite(url.lastPathComponent))
//            } else {
//                decisionHandler(.allow)
//            }
//        }
    }
    
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

            function findAElement(el) {
                let current = el

                while (current != document.body) {
                    if (current.tagName.toLowerCase() == "a") {
                        return current
                    }

                    current = current.parentElement
                }

                return false
            }

            document.addEventListener("click", (evt) => {
                let el = findAElement(evt.target)

                if (el && el.href.startsWith("https://app.revolt.chat/server")) {
                    let inviteCode = el.href.split("/").reverse()[0]
                    window.webkit.messageHandlers.serverInviteClicked.postMessage(inviteCode)
                }
            })
        """
        
        let script = WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let controller = WKUserContentController()
        
        controller.addUserScript(script)
        controller.add(context.coordinator, name: "serverInviteClicked")
        
        let config = WKWebViewConfiguration()
        config.userContentController = controller
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        
        let view = WKWebView(frame: .zero, configuration: config)
        
        view.backgroundColor = .init(viewState.theme.background.color)
        view.underPageBackgroundColor = .init(viewState.theme.background.color)
        
#if DEBUG
        view.isInspectable = true
#endif
        let request = URLRequest(url: url)
        view.load(request)

        return view
    }
    
    func makeCoordinator() -> Delegate {
        return Delegate(viewState: viewState)
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}
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

