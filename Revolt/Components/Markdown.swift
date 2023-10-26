////
////  Markdown.swift
////  Revolt
////
////  Created by Angelo on 15/10/2023.
////
//
//import Foundation
//import SwiftUI
//import MarkdownKit
//import UIKit
//
//struct UIKLabel: UIViewRepresentable {
//    
//    typealias TheUIView = UILabel
//    fileprivate var configuration = { (view: TheUIView) in }
//    
//    func makeUIView(context: UIViewRepresentableContext<Self>) -> TheUIView { TheUIView() }
//    func updateUIView(_ uiView: TheUIView, context: UIViewRepresentableContext<Self>) {
//        configuration(uiView)
//    }
//}
//
//protocol MyMarkdownElement: MarkdownElement {
//    public var text: NSString
//}
//
//extension MarkdownElement {
//    func parse(_ attributedString: NSMutableAttributedString) {
//        var location = 0
//        do {
//            let regex = try regularExpression()
//            while let regexMatch =
//                    regex.firstMatch(in: attributedString.string,
//                                     options: .withoutAnchoringBounds,
//                                     range: NSRange(location: location,
//                                                    length: attributedString.length - location))
//            {
//                let oldLength = attributedString.length
//                match(regexMatch, attributedString: attributedString)
//                let newLength = attributedString.length
//                location = regexMatch.range.location + regexMatch.range.length + newLength - oldLength
//            }
//        } catch { }
//    }
//}
//
//class UserMention: MarkdownElement {
//    func regularExpression() throws -> NSRegularExpression {
//        try NSRegularExpression(pattern: self.regex)
//    }
//    
//    var regex: String = "<@([0-9A-HJKMNP-TV-Z]{26})>"
//    var viewState: ViewState
//    
//    init(viewState: ViewState) {
//        self.viewState = viewState
//    }
//    
//    func match(_ match: NSTextCheckingResult, attributedString: NSMutableAttributedString) {
//        let range = match.range(at: 1)
//        let userId = attributedString.mutableString.substring(with: range)
//        print(userId)
//
//        let group = NSMutableAttributedString()
//        
//        group.append(NSAttributedString(attachment: RemoteImageTextAttachment(contents: { [weak self] in
//            let user = await self!.viewState.users[userId]!
//            let url = await self!.viewState.formatUrl(with: user.avatar!)
//
//            return URL(string: url)!
//        })))
//        
//        group.append(NSAttributedString(string: <#T##String#>))
//    }
//}
//
//struct Markdown: View {
//    @EnvironmentObject var viewState: ViewState
//
//    var text: String
//    var parser: MarkdownParser {
//        MarkdownParser(customElements: [UserMention(viewState: viewState)])
//    }
//
//    var body: some View {
//        
//        UIKLabel {
//            $0.attributedText = parser.parse(text)
//        }
//    }
//}
