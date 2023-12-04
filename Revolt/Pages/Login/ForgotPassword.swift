//
//  ForgotPassword.swift
//  Revolt
//
//  Created by Tom on 2023-11-16.
//

import SwiftUI

struct ForgotPassword_Reset: View {
    @EnvironmentObject var viewState: ViewState
    @Environment(\.colorScheme) var colorScheme
    
    @State var errorMessage: String? = nil
    
    @State var resetToken = ""
    @State var newPassword = ""
    
    @State var showSpinner = false
    @State var completeSpinner = false
    
    @State var goToOnboarding: Bool = false
    
    var email: String
    
    func process() {
        Task {
            do {
                _ = try await viewState.http.resetPassword(token: resetToken, password: newPassword).get()
            } catch {
                withAnimation {
                    errorMessage = "Your token was invalid or your password sucked. Direct all complaints about this message to zomatree" // TODO: get error type?
                    showSpinner = false
                }
                return
            }
            
            completeSpinner = true
            try! await Task.sleep(for: .seconds(3))
            
            await viewState.signIn(email: email, password: newPassword, callback: { state in
                switch state {
                case .Disabled, .Invalid:
                    withAnimation {
                        errorMessage = "Your account has been disabled,\nhowever the reset was successful"
                    }
                case .Onboarding: goToOnboarding = true
                default: viewState.isOnboarding = false
            }})
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            Text("Forgot your password?")
                .font(.title)
                .fontWeight(.bold)
                .padding([.leading, .trailing, .bottom])
            
            Spacer()
                .frame(maxHeight: 90)
                
            Text(errorMessage != nil ? errorMessage! : "We sent a token to your email.\nEnter it here, along with your new password")
                .font(.callout)
                .foregroundStyle(errorMessage != nil ? Color.red : (colorScheme == .light) ? Color.black : Color.white)
                .multilineTextAlignment(.center)
            
            TextField(
                "Email Token",
                text: $resetToken
            )
            .padding()
            .background((colorScheme == .light) ? Color(white: 0.851) : Color(white: 0.2))
            .clipShape(.rect(cornerRadius: 5))
            
            TextField(
                "New Password",
                text: $newPassword
            )
            .textContentType(.newPassword)
            .padding()
            .background((colorScheme == .light) ? Color(white: 0.851) : Color(white: 0.2))
            .clipShape(.rect(cornerRadius: 5))
            
            Spacer()
            
            Button(action: {
                if resetToken.isEmpty || newPassword.isEmpty {
                    withAnimation {
                        errorMessage = "Please enter the token sent to your email, and your new password"
                    }
                    return
                }
                
                withAnimation{
                    showSpinner = true
                }
                
                process()
            } ) {
                if showSpinner {
                    LoadingSpinnerView(frameSize: CGSize(width: 25, height: 25), isActionComplete: $completeSpinner)
                } else {
                    Text("Reset Password")
                }
            }
            .padding(.vertical, 10)
            .frame(width: showSpinner ? 100 : 250.0)
            .foregroundStyle(.black)
            .background(colorScheme == .light ? Color(white: 0.851) : Color.white)
            .clipShape(.rect(cornerRadius: 50))
            
            Spacer()
            Spacer()
        }
        .padding()
        .navigationDestination(isPresented: $goToOnboarding) {
            CreateAccount(onboardingStage: .Username)
        }
    }
}

struct ForgotPassword: View {
    @EnvironmentObject var viewState: ViewState
    @Environment(\.colorScheme) var colorScheme
    
    @State var errorMessage: String? = nil
    @State var email = ""
    
    @State var showSpinner = false
    @State var completeSpinner = false
    @State var captchaResult: String? = nil
    
    @State var goToResetPage = false
    
    func preProcessRequest() {
        withAnimation {
            errorMessage = nil
        }
        
        if email.isEmpty {
            withAnimation {
                errorMessage = "Enter your email"
            }
            return
        }
        
        withAnimation {
            showSpinner = true
        }
    }
    
    func processRequest() {
        Task {
            completeSpinner = true
            try! await Task.sleep(for: .seconds(3)) // let the spinner fill

            do {
                _ = try await viewState.http.createAccount_ResendVerification(email: email, captcha: captchaResult).get()
            } catch {
                withAnimation {
                    errorMessage = "Invalid email"
                    showSpinner = false
                    completeSpinner = false
                    captchaResult = nil
                }
                return
            }
            
            try! await Task.sleep(for: .seconds(1))
            goToResetPage = true
            
            try! await Task.sleep(for: .seconds(1)) // fix values after navigation change in case they press back
            showSpinner = false
            completeSpinner = false
            captchaResult = nil
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            Text("Forgot your password?")
                .font(.title)
                .fontWeight(.bold)
                .padding([.leading, .trailing, .bottom])
            
            Spacer()
                .frame(maxHeight: 50)
            
            if !showSpinner && captchaResult == nil{
                Text("Let's fix that")
                    .multilineTextAlignment(.center)
                    .font(.callout)
                
                Spacer()
                    .frame(maxHeight: 30)
            }
                
            if errorMessage != nil {
                Text(errorMessage!)
                    .font(.caption)
                    .foregroundStyle(Color.red)
            }
            TextField(
                "Email",
                text: $email
            )
            .textContentType(.emailAddress)
            #if os(iOS)
            .keyboardType(.emailAddress)
            #endif
            .padding()
            .background((colorScheme == .light) ? Color(white: 0.851) : Color(white: 0.2))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .foregroundStyle((colorScheme == .light) ? Color.black : Color.white)
            .disabled(showSpinner)
            
            if showSpinner && captchaResult == nil && viewState.apiInfo!.features.captcha.enabled {
                #if os(macOS)
                Text("No hcaptcha support")
                #else
                HCaptchaView(apiKey: viewState.apiInfo!.features.captcha.key, baseURL: viewState.http.baseURL, result: $captchaResult)
                #endif
            } else {
                Spacer()
            }
            
            Button(action: {
                preProcessRequest()
                
                if !viewState.apiInfo!.features.captcha.enabled || captchaResult != nil {
                    processRequest()
                }
            } ) {
                if showSpinner {
                    LoadingSpinnerView(frameSize: CGSize(width: 25, height: 25), isActionComplete: $completeSpinner)
                } else {
                    Text("Reset Password")
                }
            }
            .padding(.vertical, 10)
            .frame(width: showSpinner ? 100 : 250.0)
            .foregroundStyle(.black)
            .background(colorScheme == .light ? Color(white: 0.851) : Color.white)
            .clipShape(.rect(cornerRadius: 50))
            
            Spacer()
        }
        .padding()
        .onChange(of: captchaResult) {
            if captchaResult != nil {
                processRequest()
            }
        }
        .navigationDestination(isPresented: $goToResetPage) {
            ForgotPassword_Reset(email: email)
        }
    }
}

#Preview {
    NavigationStack {
        ForgotPassword_Reset(email: "")
            .environmentObject(ViewState.preview())
    }
}
