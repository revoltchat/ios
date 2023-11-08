//
//  ReportMessageSheetView.swift
//  Revolt
//
//  Created by Angelo Manca on 2023-11-05.
//

import SwiftUI

struct ReportMessageSheetView: View {
    @EnvironmentObject var viewState: ViewState
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    @State var userContext: String = ""
    @State var error: String? = nil
    @State var reason: ContentReportPayload.ContentReportReason = .NoneSpecified
    
    @Binding var showSheet: Bool
    @ObservedObject var messageView: MessageViewModel
    
    func submit() -> () {
        if reason == .NoneSpecified {
            error = "Please select a category"
        } else { error = nil }
        if userContext.isEmpty {
            if error != nil {
                error! += " and add a reason"
                
            } else {
                error = "Please add a reason"
            }
        }
        if error != nil {
            return
        }
        
        Task {
            viewState.http.logger.debug("Start report task")
            print(await viewState.http.reportMessage(id: messageView.message.id, reason: reason, userContext: userContext))
        }
        showSheet.toggle()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Spacer()
                .frame(maxHeight: 20)

            VStack(alignment: .center) {
                Text("Tell us what's wrong with this message")
                    .font(.title)
                    .multilineTextAlignment(.center)
                
                Text("Please note that this does not get sent to this server's moderators")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)

            MessageView(viewModel: messageView, isStatic: true)
                .padding(.horizontal, 5)
                .padding(.vertical, 10)

            VStack {
                Text("Pick a category")
                    .font(.caption)
                    .foregroundStyle(viewState.theme.textColor.color)
    
                Picker("Report reason", selection: $reason) {
                    ForEach(ContentReportPayload.ContentReportReason.allCases, id: \.rawValue) { reason in
                        Text(reason.rawValue)
                            .tag(reason)
                            .foregroundStyle(viewState.theme.textColor.color)
                    }
                }
                .padding(.vertical, 2)
                .frame(maxWidth: .infinity)
                .foregroundStyle(viewState.theme.textColor.color)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke((error != nil && userContext.isEmpty) ? Color.red : viewState.theme.messageBoxBorder.color, lineWidth: 1)
                )
            }

            VStack {
                Text("Give us some detail")
                    .font(.caption)
                    .foregroundStyle(viewState.theme.textColor.color)

                TextField("", text: $userContext, axis: .vertical)
                    .padding(.vertical, 15)
                    .padding(.leading)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(
                                (error != nil && userContext.isEmpty)
                                ? Color.red
                                : viewState.theme.messageBoxBorder.color,
                                lineWidth: 1)
                    )
                    .placeholder(when: userContext.isEmpty) {
                        Text("What's wrong...")
                            .padding()
                    }
                    .frame(minHeight: 50)
            }
            
            if error != nil {
                Text(error!)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
            Button(action: submit, label: {
                Text("Submit")
                    .foregroundStyle(viewState.theme.textColor.color)
            })
                .padding()
                .frame(maxWidth: .infinity)
                .background(viewState.theme.accent.color)
                .clipShape(.rect(cornerRadius: 5))

            Spacer()
        }
        .padding(.horizontal, 32)
        .background(viewState.theme.background.color)
    }
}

struct ReportMessageSheetView_Preview: PreviewProvider {
    @StateObject static var viewState = ViewState.preview()

    static var message = viewState.messages["01HD4VQY398JNRJY60JDY2QHA5"]!
    static var model = MessageViewModel(
        viewState: viewState,
        message: .constant(message),
        author: .constant(viewState.users[message.author]!),
        replies: .constant([Reply(message: message, mention: false)]),
        channelScrollPosition: .constant(nil)
    )
    
    static var previews: some View {
        ReportMessageSheetView(showSheet: .constant(true), messageView: model)
            .applyPreviewModifiers(withState: viewState.applySystemScheme(theme: .light))
        
        ReportMessageSheetView(showSheet: .constant(true), messageView: model)
            .applyPreviewModifiers(withState: viewState.applySystemScheme(theme: .dark))
    }
}
