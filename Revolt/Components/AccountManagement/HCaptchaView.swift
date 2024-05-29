//
//  HCaptchaView.swift
//  Revolt
//
//  Created by Tom on 2023-11-13.
//
// File provided under the MIT license by https://github.com/hCaptcha/HCaptcha-ios-sdk
//

#if os(iOS)
import SwiftUI
import HCaptcha
import Types

struct HCaptchaUIViewWrapperView: UIViewRepresentable {
    var uiview = UIView()

    func makeUIView(context: Context) -> UIView {
        uiview.backgroundColor = .gray
        return uiview
    }

    func updateUIView(_ view: UIView, context: Context) {
        // nothing to update
    }
}

// Example of hCaptcha usage
struct HCaptchaView: View {
    private(set) var hcaptcha: HCaptcha!
    @Binding var hCaptchaResult: String?

    let placeholder = HCaptchaUIViewWrapperView()

    var body: some View {
        VStack{
            placeholder.frame(width: 330, height: 505, alignment: .center)
        }
        .background(Color.black)
        .onAppear {
            print("captcha appeared")
            showCaptcha(placeholder.uiview)
        }
    }

    func showCaptcha(_ view: UIView) {
        hcaptcha.validate(on: view) { result in
            view.removeFromSuperview()
            let resp = try? result.dematerialize()
            print(resp)
            hCaptchaResult = resp
        }
    }


    init(apiKey: String, baseURL: String, result: Binding<String?>) {
        self._hCaptchaResult = result
        hcaptcha = try? HCaptcha(
            apiKey: apiKey,
            baseURL: URL(string: baseURL)!
        )
        let hostView = self.placeholder.uiview
        hcaptcha.configureWebView { webview in
            webview.frame = hostView.bounds
        }
    }
}

#Preview {
    var viewState = ViewState.preview()
    return HCaptchaView(apiKey: viewState.apiInfo!.features.captcha.key, baseURL: "https://api.revolt.chat/", result: .constant(nil))
}

#endif
