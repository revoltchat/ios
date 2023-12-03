//
//  ResendEmail.swift
//  Revolt
//
//  Created by Tom on 2023-11-15.
//

import SwiftUI

struct ResendEmail: View {
    @EnvironmentObject var viewState: ViewState
    @Environment(\.colorScheme) var colorScheme
    
    @State var errorMessage: String? = nil
    @State var email = ""
    
    @State var showSpinner = false
    @State var completeSpinner = false
    @State var captchaResult: String? = nil
    
    @State var goToVerificationPage = false
    
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
            goToVerificationPage = true
            
            try! await Task.sleep(for: .seconds(1)) // fix values after navigation change in case they press back
            showSpinner = false
            completeSpinner = false
            captchaResult = nil
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            Text("Didn't get an email?")
                .font(.title)
                .fontWeight(.bold)
                .padding([.leading, .trailing, .bottom])
            
            Spacer()
                .frame(maxHeight: 50)
            
            if !showSpinner && captchaResult == nil{
                Text("Enter your email, and if we've got you on record we'll send you another one")
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
            .keyboardType(.emailAddress)
            .padding()
            .background((colorScheme == .light) ? Color(white: 0.851) : Color(white: 0.2))
            .clipShape(.rect(cornerRadius: 5))
            .foregroundStyle((colorScheme == .light) ? Color.black : Color.white)
            .disabled(showSpinner)
            
            if showSpinner && captchaResult == nil && viewState.apiInfo!.features.captcha.enabled {
                HCaptchaView(apiKey: viewState.apiInfo!.features.captcha.key, baseURL: viewState.http.baseURL, result: $captchaResult)
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
                    Text("Get another code")
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
        .navigationDestination(isPresented: $goToVerificationPage) {
            CreateAccount(onboardingStage: .Verify)
        }
    }
}

#Preview {
    ResendEmail()
        .environmentObject(ViewState.preview())
}
