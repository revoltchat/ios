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
        VStack(alignment: .center) {
            Text("Tell us what's wrong with this message")
                .font(.title)
                .foregroundStyle(viewState.theme.textColor.color)
                .multilineTextAlignment(.center)
            MessageView(viewModel: messageView, isStatic: true)
            
            Spacer()
                .frame(maxHeight: 50)
            
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
                .foregroundStyle(viewState.theme.textColor.color)
                .border((error != nil && reason == .NoneSpecified) ? Color.red : viewState.theme.messageBoxBorder.color)

            Spacer()
                .frame(maxHeight: 20)
            
            Text("Give us some detail")
                .font(.caption)
                .foregroundStyle(viewState.theme.textColor.color)
            TextField("What's wrong...", text: $userContext, axis: .vertical)
                .padding(.top, 15)
                .padding(.bottom, 20)
                .frame(minHeight: 50)
                .foregroundStyle(viewState.theme.textColor.color)
                .backgroundStyle(viewState.theme.messageBox.color)
                .border((error != nil && userContext.isEmpty) ? Color.red : viewState.theme.messageBoxBorder.color)
            
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
                .frame(width: 200)
                .clipShape(.rect(cornerRadius: 50))
                .background(viewState.theme.accent.color)
            Spacer()
        }
        .background(viewState.theme.background.color)
    }
}

#Preview {
    @StateObject var viewState = ViewState.preview()
    var message = viewState.messages["01HD4VQY398JNRJY60JDY2QHA5"]!
    var model = MessageViewModel(
        viewState: viewState,
        message: .constant(message),
        author: .constant(viewState.users[message.author]!),
        replies: .constant([Reply(message: message, mention: false)]),
        channelScrollPosition: .constant(nil)
    )
    
    return ReportMessageSheetView(showSheet: .constant(true), messageView: model)
}
