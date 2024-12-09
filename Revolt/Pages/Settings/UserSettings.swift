//
//  UserSettings.swift
//  Revolt
//
//  Created by Angelo on 2024-02-10.
//

import SwiftUI
import OSLog
import Sentry
import Alamofire // literally just for types
import UniformTypeIdentifiers


let log = Logger(subsystem: "app.revolt.chat", category: "UserSettingsViews")

func generateTOTPUrl(secret: String, email: String) -> String {
    return "otpauth://totp/Revolt:\(email)?secret=\(secret)&issuer=Revolt"
}


/// Takes a callback that receives either the totp code or the recovery code (in that argument order).
/// Wont be called if neither are found.
func maybeGetPasteboardValue(_ callback: (String?, String?) -> ()) {
    #if os(iOS)
    let pasteboardItem = UIPasteboard.general.string
    #elseif os(macOS)
    let pasteboardItem = NSPasteboard.general.string(forType: .string)
    #endif
    if let pasteboardItem = pasteboardItem {
        let regex = /(?<totp>\d{6})|(?<recovery>[a-z0-9]{5}-[a-z0-9]{5})/
        if let match = try? regex.wholeMatch(in: pasteboardItem) {
            if match.output.recovery != nil {
                callback(nil, String(match.output.recovery!))
            } else if match.output.totp != nil {
                callback(String(match.output.totp!), nil)
            }
        }
    }
}

// MARK: - MFA stuff

fileprivate struct CreateMFATicketView: View {
    @EnvironmentObject var viewState: ViewState
    @State private var fieldIsIncorrect = false
    @State private var fieldShake = false
    @State private var fieldValue = ""
    
    /// RecoveryCode is for internal use
    enum RequestTicketType { case Password, Code, RecoveryCode }
    
    var requestTicketType: RequestTicketType
    var doneCallback: (MFATicketResponse) -> ()
    
    func setBadField() {
        withAnimation {
            fieldIsIncorrect = true
        }
        
        fieldShake = true
        withAnimation(Animation.spring(response: 0.2, dampingFraction: 0.2, blendDuration: 0.2)) {
            fieldShake = false
        }
    }
    
    func submitForTicket() async {
        if fieldIsIncorrect {
            withAnimation {
                fieldIsIncorrect = false
            }
        }
        
        if fieldValue.isEmpty {
            setBadField()
            return
        }
        
        var requestType = requestTicketType
        if requestTicketType == .Code && fieldValue.contains("-") {
            requestType = .RecoveryCode
        }
        
        let resp = switch requestType {
        case .Password:
            await viewState.http.submitMFATicket(password: fieldValue)
        case .Code:
            await viewState.http.submitMFATicket(totp: fieldValue)
        case .RecoveryCode:
            await viewState.http.submitMFATicket(recoveryCode: fieldValue)
        }
        
        let ticket = try? resp.get()
        
        if ticket == nil {
            setBadField()
            return
        }
        
        doneCallback(ticket!)
    }
    
    func receivePasteboardCallback(totp: String?, recovery: String?) {
        if totp != nil {
            fieldValue = totp!
            Task { await submitForTicket() }
        } else if recovery != nil {
            fieldValue = recovery!
            Task { await submitForTicket() }
        }
    }
    
    var body: some View {
        VStack {
            Text("Hold Up!", comment: "title prompt for password when setting up totp")
                .font(.title)
            if requestTicketType == .Password {
                Text("This area is guarded by trolls. Tell them your password to continue.", comment: "subtitle prompt for password when setting up totp")
                    .font(.title2)
            } else {
                Text("This area is guarded by trolls. Fetch them your TOTP code to continue.", comment: "subtitle prompt for password when modifying totp")
                    .font(.title2)
            }
            Spacer()
                .frame(maxHeight: 50)
            
            if requestTicketType == .Password {
                SecureField(String(localized: "Enter Password", comment: "Password prompt"), text: $fieldValue)
                    .textContentType(.password)
                    .offset(x: fieldShake ? 30 : 0)
                    .onChange(of: fieldValue) { _, _ in
                        if fieldIsIncorrect {
                            withAnimation {
                                fieldIsIncorrect = false
                            }
                        }
                    }
                    .onSubmit {
                        Task { await submitForTicket() }
                    }
            } else {
                // TODO: this needs something to toggle to recovery code mode
                TextField(String(localized: "Enter TOTP code", comment: "Authenticator prompt"), text: $fieldValue)
                    .textContentType(.oneTimeCode)
                    .offset(x: fieldShake ? 30 : 0)
                #if os(iOS)
                    .keyboardType(UIKeyboardType.numberPad)
                #endif
                    .onChange(of: fieldValue) { _, _ in
                        if fieldIsIncorrect {
                            withAnimation {
                                fieldIsIncorrect = false
                            }
                        }
                        
                        if fieldValue.count == 6 {
                            Task { await submitForTicket() }
                        }
                    }
                    .onSubmit {
                        Task { await submitForTicket() }
                    }
                    .onTapGesture {
                        maybeGetPasteboardValue(receivePasteboardCallback)
                    }
            }
            if fieldIsIncorrect {
                if !fieldValue.isEmpty {
                    Text("Try again", comment: "the user entered an incorrect password")
                        .foregroundStyle(Color.red)
                        .font(.caption)
                } else {
                    Text("You must enter your password", comment: "the user entered a blank password")
                        .foregroundStyle(Color.red)
                        .font(.caption)
                }
            }
        }
    }
}

fileprivate struct AddTOTPSheet: View {
    private enum Phase { case Password, Code, Verify, FatalError}
    @EnvironmentObject var viewState: ViewState
    @State private var currentPhase: Phase = .Password
    @Binding var showSheet: Bool
    
    @State var OTP = ""
    @State var fieldShake = false
    @State var fieldIsIncorrect = false
    
    @State var ticket: MFATicketResponse? = nil
    
    @State var secret: String? = nil
    
    func setBadField() {
        withAnimation {
            fieldIsIncorrect = true
        }
        
        fieldShake = true
        withAnimation(Animation.spring(response: 0.2, dampingFraction: 0.2, blendDuration: 0.2)) {
            fieldShake = false
        }
    }
    
    func receiveTicket(mfaTicket: MFATicketResponse) async {
        ticket = mfaTicket
        
        let secretResp = await viewState.http.getTOTPSecret(mfaToken: ticket!.token)
        do {
            let secretModel = try secretResp.get()
            secret = secretModel.secret
            
            withAnimation {
                currentPhase = .Code
            }
        } catch {
            log.error("Errored out attempting to receive TOTP secret: \(error.localizedDescription)")
            withAnimation {
                currentPhase = .FatalError
            }
        }
    }
    
    func finalize() async {
        if fieldIsIncorrect {
            withAnimation {
                fieldIsIncorrect = false
            }
        }
        
        if OTP.isEmpty {
            setBadField()
            return
        }
        
        let resp = await viewState.http.enableTOTP(mfaToken: ticket!.token, totp_code: OTP)
        
        do {
            _ = try resp.get()
        } catch {
            setBadField()
            return
        }
        
        showSheet = false
    }
    
    func receivePasteboardCallback(totp: String?, recovery: String?) {
        if totp != nil {
            OTP = totp!
            Task { await finalize() }
        }
    }
    
    var body: some View {
        VStack {
            if currentPhase == .Password {
                CreateMFATicketView(requestTicketType: .Password, doneCallback: {ticket in Task{await receiveTicket(mfaTicket: ticket)}})
            }
            else if currentPhase == .Code {
                Text("Code time", comment: "debug print, dont translate")
                Spacer()
                    .frame(maxHeight: 10)
                Text(secret!)
                    .selectionDisabled(false)
                    .onTapGesture {
                        copyText(text: secret!)
                    }
                Spacer()
                    .frame(maxHeight: 10)
                Link(destination: URL(
                    string: generateTOTPUrl(
                        secret: secret!,
                        email: viewState.userSettingsStore.cache.accountData!.email
                    ))!) {
                        Text("Open in authenticator app", comment: "open the user's authenticator app")
                    }
                    .foregroundStyle(Color.blue)
                Spacer()
                    .frame(maxHeight: 10)
                Button(action: {
                    withAnimation {
                        currentPhase = .Verify
                    }
                }) {
                    Text("Next")
                }
            }
            else if currentPhase == .Verify {
                Text("Verify time", comment: "debug print, dont translate")
                Text("Enter the code provided by your authenticator app", comment: "prompting the user for their OTP while setting up TOTP")
                TextField(String(localized: "code", comment: "TOTP code"), text: $OTP)
                    .textContentType(.oneTimeCode)
                    .onSubmit {
                        Task{ await finalize() }
                    }
                #if os(iOS)
                    .keyboardType(.numberPad)
                #endif
                    .onTapGesture {
                        maybeGetPasteboardValue(receivePasteboardCallback)
                    }
                    .onAppear {
                        maybeGetPasteboardValue(receivePasteboardCallback)
                    }
            }
            else if currentPhase == .FatalError {
                Text("Something went wrong. Try again later?")
            }
        }
        .padding()
        .transition(.slide)
    }
}


fileprivate struct RemoveTOTPSheet: View {
    @EnvironmentObject var viewState: ViewState
    @Binding var showSheet: Bool
    @State var errorOccurred = false
    
    func removeTOTP(ticket: MFATicketResponse) {
        Task {
            do {
                print(try await viewState.http.disableTOTP(mfaToken: ticket.token).get())
                showSheet = false
            } catch {
                let error = error as! RevoltError
                SentrySDK.capture(error: error)
                
                withAnimation {
                    errorOccurred = true
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            CreateMFATicketView(requestTicketType: .Password, doneCallback: removeTOTP)
            if errorOccurred {
                Spacer()
                    .frame(maxHeight: 10)
                Text("Something went wrong. Try again later?")
                    .foregroundStyle(.red)
            }
        }
        .padding()
    }
}

fileprivate struct GenerateRecoveryCodesSheet: View {
    @EnvironmentObject var viewState: ViewState
    @Binding var showSheet: Bool
    @Binding var sheetIsNotDismissable: Bool
    @State var errorOccurred = false
    @State var codes: [String] = []
    @State var copyButtonText = String(localized: "Copy to clipboard")
    @State var isCopyDisabled = false
    
    func generateCodes(ticket: MFATicketResponse) {
        Task {
            do {
                let _codes = try await viewState.http.generateRecoveryCodes(mfaToken: ticket.token).get()
                
                sheetIsNotDismissable = true
                withAnimation {
                    codes = _codes
                }
            } catch {
                let error = error as! RevoltError
                SentrySDK.capture(error: error)
                
                withAnimation {
                    errorOccurred = true
                }
            }
        }
    }
    
    // known bug: the MFATicketview doesnt fully slide offscreen
    var body: some View {
        VStack {
            if codes.isEmpty {
                CreateMFATicketView(requestTicketType: .Password, doneCallback: generateCodes)
                    .transition(.slideNext)
            } else {
                VStack {
                    ForEach(0 ..< codes.count, id: \.self) { value in
                        Text(codes[value])
                            .font(.subheadline)
                            .fontWeight(.heavy)
                            .padding(5)
                            .textSelection(.enabled)
                    }
                    Spacer()

                    Button(action: {
                        let content = codes.joined(separator: "\n")
                        UIPasteboard.general.setValue(content, forPasteboardType: UTType.plainText.identifier)
                        
                        withAnimation {
                            copyButtonText = String(localized: "Copied!")
                            isCopyDisabled = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: {
                            withAnimation {
                                copyButtonText = String(localized: "Copy to clipboard")
                                isCopyDisabled = false
                            }
                        })
                    }) {
                        Text(copyButtonText)
                    }
                    .padding(.vertical, 10)
                    .frame(width: 250.0)
                    .foregroundStyle(viewState.theme.foreground)
                    .background(viewState.theme.background2)
                    .clipShape(.rect(cornerRadius: 50))
                    .disabled(isCopyDisabled)
                    
                    Button(action: {
                        showSheet = false
                    }) {
                        Text("Done")
                    }
                    .padding(.vertical, 10)
                    .frame(width: 250.0)
                    .foregroundStyle(viewState.theme.foreground)
                    .background(viewState.theme.background2)
                    .clipShape(.rect(cornerRadius: 50))
                }
                .backgroundStyle(viewState.theme.background2)
                .padding()
                .transition(.slideNext)
            }
            if errorOccurred {
                Spacer()
                    .frame(maxHeight: 10)
                Text("Something went wrong. Try again later?")
                    .foregroundStyle(.red)
            }
        }
        .padding()
    }
}

// MARK: - Account fields

fileprivate struct UsernameUpdateSheet: View {
    @EnvironmentObject var viewState: ViewState
    @Binding var showSheet: Bool
    
    @State var value: String
    @State var password: String = ""
    
    @FocusState var nameFieldState: Bool
    @FocusState var passwordFieldState: Bool
    
    @State var errorOccurred = false
    
    init(viewState: ViewState, showSheet sheet: Binding<Bool>) {
        _showSheet = sheet
        _value = State(initialValue: "")
        _value.wrappedValue = viewState.userSettingsStore.cache.user!.username
    }
    
    func submitName() async {
        do {
            _ = try await viewState.http.updateUsername(newName: value, password: password).get()
            showSheet = false
        } catch {
            // TODO: better error messages
            withAnimation {
                errorOccurred = true
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                TextField("Enter a new username", text: $value)
                    .textContentType(.username)
                    .font(.title2)
                    .frame(height: 30)
                    .textFieldStyle(.roundedBorder)
                    .background(viewState.theme.background2)
                    .foregroundStyle(viewState.theme.foreground)
                    .onSubmit {
                        if password.isEmpty {
                            passwordFieldState = true
                        } else {
                            Task {
                                await submitName()
                            }
                        }
                    }
                    .focused($nameFieldState)
                Text("#\(viewState.userSettingsStore.cache.user!.discriminator)")
                    //.addBorder(viewState.theme.accent, cornerRadius: 1.0)
            }
            Spacer()
                .frame(maxHeight: 30)
            SecureField("Password", text: $password)
                .textContentType(.password)
                .onSubmit {
                    if value.isEmpty {
                        nameFieldState = true
                    } else {
                        Task {
                            await submitName()
                        }
                    }
                }
                .font(.title2)
                .frame(height: 30)
                .focused($passwordFieldState)
                .textFieldStyle(.roundedBorder)
                .background(viewState.theme.background2)
                //.clipShape(.rect(cornerRadius: 30))
            if errorOccurred {
                Text("The trolls have rejected your password")
                    .foregroundStyle(Color.red)
            }
            Spacer()
                .frame(minHeight: 30, maxHeight: 70)
            Button(action: {
                if value.isEmpty {
                    nameFieldState = true
                } else if password.isEmpty {
                    passwordFieldState = true
                } else {
                    Task {
                        await submitName()
                    }
                }
            }) {
                Text("Change it", comment: "'done' button for changing username")
            }
            .padding(.vertical, 10)
            .frame(width: 250.0)
            .foregroundStyle(viewState.theme.foreground)
            .background(viewState.theme.background2)
            .clipShape(.rect(cornerRadius: 50))
        }
        .onChange(of: value, {_, _ in errorOccurred = false})
        .onChange(of: password, {_, _ in errorOccurred = false})
    }
}


fileprivate struct PasswordUpdateSheet: View {
    @EnvironmentObject var viewState: ViewState
    @Binding var showSheet: Bool
    
    @State var oldPassword: String = ""
    @State var newPassword: String = ""
    
    @FocusState var oldPasswordFocus: Bool
    @FocusState var newPasswordFocus: Bool
    
    @State var errorOccurred = false
    
    func submitPassword() async {
        do {
            _ = try await viewState.http.updatePassword(newPassword: newPassword, oldPassword: oldPassword).get()
            showSheet = false
        } catch {
            // TODO: better error messages
            withAnimation {
                errorOccurred = true
            }
        }
    }
    
    var body: some View {
        VStack {
            SecureField("Old Password", text: $oldPassword)
                .textContentType(.password)
                .font(.title2)
                .frame(height: 30)
                .textFieldStyle(.roundedBorder)
                .background(viewState.theme.background2)
                .foregroundStyle(viewState.theme.foreground)
                .onSubmit {
                    if newPassword.isEmpty {
                        newPasswordFocus = true
                    } else {
                        Task {
                            await submitPassword()
                        }
                    }
                }
                .focused($oldPasswordFocus)
            Spacer()
                .frame(maxHeight: 30)
            SecureField("New Password", text: $newPassword)
                .textContentType(.newPassword)
                .font(.title2)
                .frame(height: 30)
                .textFieldStyle(.roundedBorder)
                .background(viewState.theme.background2)
                .onSubmit {
                    if oldPassword.isEmpty {
                        oldPasswordFocus = true
                    } else {
                        Task {
                            await submitPassword()
                        }
                    }
                }
                .focused($oldPasswordFocus)
            
            if errorOccurred {
                Text("The trolls have rejected your old password", comment: "The password was rejected by the server")
                    .foregroundStyle(Color.red)
            }
            Spacer()
                .frame(minHeight: 30, maxHeight: 70)
            Button(action: {
                if oldPassword.isEmpty {
                    oldPasswordFocus = true
                } else if newPassword.isEmpty {
                    newPasswordFocus = true
                } else {
                    Task {
                        await submitPassword()
                    }
                }
            }) {
                Text("Change it", comment: "'done' button for changing password")
            }
            .padding(.vertical, 10)
            .frame(width: 250.0)
            .foregroundStyle(viewState.theme.foreground)
            .background(viewState.theme.background2)
            .clipShape(.rect(cornerRadius: 50))
        }
        .onChange(of: oldPassword, {_, _ in errorOccurred = false})
        .onChange(of: newPassword, {_, _ in errorOccurred = false})
    }
}

fileprivate struct DisableAccountSheet: View {
    @EnvironmentObject var viewState: ViewState
    @Binding var showSheet: Bool
    @State var ticket: MFATicketResponse? = nil
    @State var errorOccurred = false
    @State var presentConfirmationDialog = false
    
    func receiveTicket(ticket: MFATicketResponse) {
        withAnimation {
            self.ticket = ticket
        }
    }
    
    func deactivateAccount() {
        Task {
            do {
                _ = try await viewState.http.disableAccount(mfaToken: ticket!.token).get()
            } catch {
                SentrySDK.capture(error: error)
                
                withAnimation {
                    errorOccurred = true
                }
                return
            }
            
            viewState.ws?.stop()
            showSheet = false

            withAnimation {
                viewState.state = .signedOut
            }
        }
    }
    
    var body: some View {
        if ticket == nil {
            CreateMFATicketView(requestTicketType: .Password, doneCallback: receiveTicket)
                .transition(.slideNext)
        } else {
            VStack {
                Text("Wait a minute!")
                    .font(.title)
                Text("Are you sure you want to disable your account?")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                Spacer()
                    .frame(maxHeight: 10)
                Text("This will prevent you from being able to sign in. You'll need to message support to get your account reactivated.")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                Button(role: .destructive, action: {
                    presentConfirmationDialog = true
                }) {
                    Text("Do it")
                }
                .padding(.vertical, 10)
                .frame(width: 250.0)
                .foregroundStyle(viewState.theme.foreground)
                .background(viewState.theme.background2)
                .clipShape(.rect(cornerRadius: 50))
                
                Spacer()
                    .frame(maxHeight: 10)
                
                Button(role: .cancel, action: {
                    showSheet = false
                }) {
                    Text("Go back")
                }
                .padding(.vertical, 10)
                .frame(width: 250.0)
                .foregroundStyle(viewState.theme.foreground)
                .background(viewState.theme.background2)
                .clipShape(.rect(cornerRadius: 50))
            }
            .confirmationDialog("Confirm disabling your account", isPresented: $presentConfirmationDialog) {
                Button("Confirm", role: .destructive) {
                    deactivateAccount()
                }
            }
            .transition(.slideNext)
            
            if errorOccurred {
                Spacer()
                    .frame(maxHeight: 10)
                Text("Something went wrong. Try again later?")
                    .foregroundStyle(.red)
            }
        }
    }
}


fileprivate struct DeleteAccountSheet: View {
    @EnvironmentObject var viewState: ViewState
    @Binding var showSheet: Bool
    @State var ticket: MFATicketResponse? = nil
    @State var errorOccurred = false
    @State var presentConfirmationDialog = false
    
    func receiveTicket(ticket: MFATicketResponse) {
        withAnimation {
            self.ticket = ticket
        }
    }
    
    func deleteAccount() {
        Task {
            do {
                _ = try await viewState.http.deleteAccount(mfaToken: ticket!.token).get()
            } catch {
                SentrySDK.capture(error: error)
                
                withAnimation {
                    errorOccurred = true
                }
                return
            }
            
            viewState.ws?.stop()
            showSheet = false

            withAnimation {
                viewState.state = .signedOut
            }
        }
    }
    
    var body: some View {
        if ticket == nil {
            CreateMFATicketView(requestTicketType: .Password, doneCallback: receiveTicket)
                .transition(.slideNext)
        } else {
            VStack {
                Text("Stop right there!")
                    .font(.title)
                Text("Are you sure you want to delete your account?")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                Spacer()
                    .frame(maxHeight: 10)
                Text("Your account will be disabled, and may be reactivated by opening a support request. After a week, it will be permenantly deleted.")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                Button(role: .destructive, action: {
                    presentConfirmationDialog = true
                }) {
                    Text("Do it")
                }
                .padding(.vertical, 10)
                .frame(width: 250.0)
                .foregroundStyle(viewState.theme.foreground)
                .background(viewState.theme.background2)
                .clipShape(.rect(cornerRadius: 50))
                
                Spacer()
                    .frame(maxHeight: 10)
                
                Button(role: .cancel, action: {
                    showSheet = false
                }) {
                    Text("Go back")
                }
                .padding(.vertical, 10)
                .frame(width: 250.0)
                .foregroundStyle(viewState.theme.foreground)
                .background(viewState.theme.background2)
                .clipShape(.rect(cornerRadius: 50))
            }
            .confirmationDialog("Confirm deleting your account", isPresented: $presentConfirmationDialog) {
                Button("Confirm", role: .destructive) {
                    deleteAccount()
                }
            }
            .transition(.slideNext)
            
            if errorOccurred {
                Spacer()
                    .frame(maxHeight: 10)
                Text("Something went wrong. Try again later?")
                    .foregroundStyle(.red)
            }
        }
    }
}

struct UserSettings: View {
    @EnvironmentObject var viewState: ViewState
    
    // Everything here should be a sheet, no making navlinks!
    @State var presentGenerateCodesSheet = false
    @State var GenerateCodeSheetIsNotDismissable = false
    @State var presentAddTOTPSheet = false
    @State var presentRemoveTOTPSheet = false
    @State var presentChangeUsernameSheet = false
    @State var presentChangeEmailSheet = false
    @State var presentChangePasswordSheet = false
    @State var presentDisableAccountSheet = false
    @State var presentDeleteAccountSheet = false
    
    @State var emailSubstitute = "loading..."
    
    func substituteEmail(_ email: String) -> String {
        let groups = try! /(?<addr>[^@]+)\@(?<url>[^.]+)\.(?<domain>.+)/.wholeMatch(in: email)
        guard let groups = groups else { return "loading@loading.com" }
        
        // cursed
        let m1 = String(repeating: "•", count: groups.output.addr.count)
        let m2 = String(repeating: "•", count: groups.output.url.count)
        let m3 = String(repeating: "•", count: groups.output.domain.count)
        let resp = "\(m1)@\(m2).\(m3)"
        emailSubstitute = resp
        return resp
    }
    
    var body: some View {
        List {
            Section("Account Info") {
                HStack {
                    Text("Server")
                    Spacer()
                    if let apiInfo = viewState.apiInfo {
                        Text(URL(string: apiInfo.app)?.host ?? "")
                            .foregroundStyle(.secondary)
                    }
                }
                .listRowBackground(viewState.theme.background2)
                
                Button(action: {
                    presentChangeUsernameSheet = true
                }) {
                    HStack {
                        Text("Username")
                        Spacer()
                        if viewState.userSettingsStore.cache.user != nil {
                            Text(verbatim: "\(viewState.userSettingsStore.cache.user!.username)#\(viewState.userSettingsStore.cache.user!.discriminator)")
                        } else {
                            Text("loading#0000", comment: "The username is still loading from the api")
                        }
                    }
                }
                Button(action: {
                    presentChangeEmailSheet = true
                }) {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(verbatim: emailSubstitute)
                            .onChange(of: viewState.userSettingsStore.cache.accountData?.email, { _, value in
                                let raw = viewState.userSettingsStore.cache.accountData?.email
                                guard let raw = raw else { return }
                                _ = substituteEmail(raw)
                            })
                    }
                }
                Button(action: {
                    presentChangePasswordSheet = true
                }) {
                    HStack {
                        Text("Change Password")
                        Spacer()
                    }
                }
            }
            .listRowBackground(viewState.theme.background2)
            
            Section("Two-Factor Authentication") {
                if viewState.userSettingsStore.cache.accountData?.mfaStatus == nil {
                    Text("Loading Data...", comment: "User setings notice - still fetching data")
                } else {
                    if !viewState.userSettingsStore.cache.accountData!.mfaStatus.anyMFA { // MFA not enabled.
                        Text("You have not enabled two-factor authentication!", comment: "User settings info notice") // idk thisll do for now
                            .font(.callout)
                    }
                    Button(action: {
                        presentGenerateCodesSheet = true
                    }, label: {
                        if !viewState.userSettingsStore.cache.accountData!.mfaStatus.recovery_active {
                            Text("Generate Recovery Codes", comment: "User settings button")
                                .foregroundStyle(viewState.theme.foreground)
                        } else {
                            Text("Regenerate Recovery Codes", comment: "User settings button")
                                .foregroundStyle(viewState.theme.foreground)
                        }
                    })
                    if !viewState.userSettingsStore.cache.accountData!.mfaStatus.totp_mfa {
                        Button(action: {
                            presentAddTOTPSheet = true
                        }, label: {
                            Text("Add Authenticator", comment: "User settings button")
                        })
                    } else {
                        Button(action: {
                            presentRemoveTOTPSheet = true
                        }, label: {
                            Text("Remove Authenticator", comment: "User settings button")
                        })
                    }
                }
            }
            .listRowBackground(viewState.theme.background2)
            
            Section("Account Management") {
                Button(action: {
                    presentDisableAccountSheet = true
                }, label: {
                    Text("Disable Account", comment: "User settings button")
                        .foregroundStyle(.red)
                })
                
                Button(action: {
                    presentDeleteAccountSheet = true
                }, label: {
                    Text("Delete Account", comment: "User settings button")
                        .foregroundStyle(.red)
                })
            }
            .listRowBackground(viewState.theme.background2)
        }
        .background(viewState.theme.background)
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Account Settings", comment: "User Settings tooltip")
            }
        }
        .toolbarBackground(viewState.theme.topBar, for: .automatic)
        .refreshable {
            await viewState.userSettingsStore.fetchFromApi()
        }
        .onAppear {
            let raw = viewState.userSettingsStore.cache.accountData?.email
            guard let raw = raw else {
                Task {
                    await viewState.userSettingsStore.fetchFromApi()
                }
                return
            }
            emailSubstitute = substituteEmail(raw)

        }
        .sheet(isPresented: $presentGenerateCodesSheet, onDismiss: {
            Task {
                await viewState.userSettingsStore.fetchFromApi()
            }
        }) {
            SettingsSheetContainer(showSheet: $presentGenerateCodesSheet) {
                GenerateRecoveryCodesSheet(showSheet: $presentGenerateCodesSheet, sheetIsNotDismissable: $GenerateCodeSheetIsNotDismissable)
            }
            .presentationBackground(viewState.theme.background)
            .interactiveDismissDisabled(GenerateCodeSheetIsNotDismissable)
        }
        .sheet(isPresented: $presentAddTOTPSheet, onDismiss: {
            Task {
                await viewState.userSettingsStore.fetchFromApi()
            }
        }) {
            SettingsSheetContainer(showSheet: $presentAddTOTPSheet) {
                AddTOTPSheet(showSheet: $presentAddTOTPSheet)
            }
            .presentationBackground(viewState.theme.background)
        }
        .sheet(isPresented: $presentRemoveTOTPSheet, onDismiss: {
            Task {
                await viewState.userSettingsStore.fetchFromApi()
            }
        }) {
            SettingsSheetContainer(showSheet: $presentRemoveTOTPSheet) {
                RemoveTOTPSheet(showSheet: $presentRemoveTOTPSheet)
            }
            .presentationBackground(viewState.theme.background)
        }
        .sheet(isPresented: $presentChangeUsernameSheet, onDismiss: {
            Task {
                await viewState.userSettingsStore.fetchFromApi()
            }
        }) {
            SettingsSheetContainer(showSheet: $presentChangeUsernameSheet) {
                UsernameUpdateSheet(viewState: viewState, showSheet: $presentChangeUsernameSheet)
            }
            .presentationBackground(viewState.theme.background)
        }
        .sheet(isPresented: $presentChangePasswordSheet) {
            SettingsSheetContainer(showSheet: $presentChangePasswordSheet) {
                PasswordUpdateSheet(showSheet: $presentChangePasswordSheet)
            }
            .presentationBackground(viewState.theme.background)
        }
        .sheet(isPresented: $presentDisableAccountSheet) {
            SettingsSheetContainer(showSheet: $presentDisableAccountSheet) {
                DisableAccountSheet(showSheet: $presentDisableAccountSheet)
            }
            .presentationBackground(viewState.theme.background)
        }
        .sheet(isPresented: $presentDeleteAccountSheet) {
            SettingsSheetContainer(showSheet: $presentDeleteAccountSheet) {
                DeleteAccountSheet(showSheet: $presentDeleteAccountSheet)
            }
            .presentationBackground(viewState.theme.background)
        }
    }
}

