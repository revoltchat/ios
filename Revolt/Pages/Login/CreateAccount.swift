//
//  CreateAccount.swift
//  Revolt
//
//  Created by Tom on 2023-11-13.
//

import SwiftUI

struct CreateAccount: View {
    enum OnboardingStage {
        case Initial
        case Verify
        case Username
    }
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewState: ViewState

    @State private var email = ""
    @State private var password = ""
    @State private var verifyCode = ""
    @State private var username = ""
    @State private var showPassword = false
    @State private var errorMessage: String? = nil
    
    @State private var isWaitingWithSpinner = false
    @State private var isSpinnerComplete = false
    @State private var hCaptchaResult: String? = nil
    
    @State var onboardingStage = OnboardingStage.Initial
    
    @FocusState private var focus1: Bool
    @FocusState private var focus2: Bool
    
    @FocusState private var autoFocusPull: Bool
    
    var body: some View {
        ZStack {
            VStack {
                if !isWaitingWithSpinner && onboardingStage == .Initial {
                    Spacer()
                }

                Text("Let's sign you up")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding([.leading, .trailing, .bottom])
                    .foregroundStyle((colorScheme == .light) ? Color.black : Color.white)
                
                if !isWaitingWithSpinner && onboardingStage == .Initial {
                    Group {
                        if let error = errorMessage {
                            Text(error)
                                .foregroundStyle(Color.red)
                        }
                        TextField(
                            "Email",
                            text: $email
                        )
                        .padding()
                        .background((colorScheme == .light) ? Color(white: 0.851) : Color(white: 0.2))
                        .clipShape(.rect(cornerRadius: 5))
                        .foregroundStyle((colorScheme == .light) ? Color.black : Color.white)
                        .disabled(isWaitingWithSpinner)
                        .focused($autoFocusPull)

                        ZStack(alignment: .trailing) {
                            TextField(
                                "Password",
                                text: $password
                            )
                            .padding()
                            .background((colorScheme == .light) ? Color(white: 0.851) : Color(white: 0.2))
                            .clipShape(.rect(cornerRadius: 5))
                            .modifier(PasswordModifier())
                            .textContentType(.password)
                            .foregroundStyle((colorScheme == .light) ? Color.black : Color.white)
                            .opacity(showPassword ? 1 : 0)
                            .focused($focus1)
                            .disabled(isWaitingWithSpinner)
                            
                            SecureField(
                                "Password",
                                text: $password
                            )
                            .padding()
                            .background((colorScheme == .light) ? Color(white: 0.851) : Color(white: 0.2))
                            .clipShape(.rect(cornerRadius: 5))
                            .modifier(PasswordModifier())
                            .textContentType(.password)
                            .foregroundStyle((colorScheme == .light) ? Color.black : Color.white)
                            .opacity(showPassword ? 0 : 1)
                            .focused($focus2)
                            .disabled(isWaitingWithSpinner)
                            
                            Button(action: {
                                showPassword.toggle()
                                if showPassword {
                                    focus1 = true
                                } else {
                                    focus2 = true
                                }
                            }, label: {
                                if colorScheme == .light {
                                    Image(systemName: self.showPassword ? "eye.slash.fill" : "eye.fill")
                                        .font(.system(size: 16, weight: .regular))
                                        .padding()
                                } else {
                                    Image(systemName: self.showPassword ? "eye.slash.fill" : "eye.fill")
                                        .font(.system(size: 16, weight: .regular))
                                        .padding()
                                        .colorInvert()
                                }
                            })
                        }
                    }
                    .padding(.bottom)
                    .onAppear {
                        autoFocusPull = true
                    }
                } else if onboardingStage == .Verify {
                    Group {
                        if let error = errorMessage {
                            Text(error)
                                .foregroundStyle(Color.red)
                        } else {
                            Text("Enter the verification code sent to your email")
                                .multilineTextAlignment(.center)
                                .foregroundStyle((colorScheme == .light) ? Color.black : Color.white)
                        }
                        TextField(
                            "Verification Code",
                            text: $verifyCode
                        )
                        .textContentType(.oneTimeCode)
                        .padding()
                        .background((colorScheme == .light) ? Color(white: 0.851) : Color(white: 0.2))
                        .clipShape(.rect(cornerRadius: 5))
                        .foregroundStyle((colorScheme == .light) ? Color.black : Color.white)
                        .disabled(isWaitingWithSpinner)
                        .focused($autoFocusPull)
                    }
                    .onAppear {
                        autoFocusPull = true
                    }
                }
                else if onboardingStage == .Username {
                    Group {
                        if let error = errorMessage {
                            Text(error)
                                .foregroundStyle(Color.red)
                        } else {
                            Text("Enter your Username")
                                .multilineTextAlignment(.center)
                                .foregroundStyle((colorScheme == .light) ? Color.black : Color.white)
                        }
                        TextField(
                            "Username",
                            text: $username
                        )
                        .textContentType(.oneTimeCode)
                        .padding()
                        .background((colorScheme == .light) ? Color(white: 0.851) : Color(white: 0.2))
                        .clipShape(.rect(cornerRadius: 5))
                        .foregroundStyle((colorScheme == .light) ? Color.black : Color.white)
                        .disabled(isWaitingWithSpinner)
                        .focused($autoFocusPull)
                    }
                    .onAppear {
                        autoFocusPull = true
                    }
                }
                
                
                Spacer()

                Group {
                        Button(action: {
                            autoFocusPull = false // reset focus state so it gets reenabled on state change via onAppear
                            
                            if onboardingStage == .Initial {
                                if email.isEmpty || password.isEmpty {
                                    withAnimation {
                                        errorMessage = "Please enter your email and password"
                                    }
                                    return
                                }
                                errorMessage = nil
                                if viewState.apiInfo!.features.captcha.enabled && hCaptchaResult == nil {
                                    withAnimation {
                                        isWaitingWithSpinner.toggle()
                                    }
                                } else {
                                    Task {
                                        do {
                                            _ = try await viewState.http.createAccount(email: email, password: password, invite: nil, captcha: hCaptchaResult).get()
                                        } catch {
                                            withAnimation {
                                                isSpinnerComplete = false
                                                isWaitingWithSpinner = false
                                                errorMessage = "Sorry, your email or password was invalid"
                                            }
                                            return
                                        }
                                        withAnimation {
                                            isWaitingWithSpinner = false
                                            isSpinnerComplete = false
                                            onboardingStage = .Verify
                                        }
                                    }
                                }
                            }
                            else if onboardingStage == .Verify {
                                if verifyCode.isEmpty {
                                    withAnimation {
                                        errorMessage = "Please enter the verification code"
                                    }
                                    return
                                }
                                errorMessage = nil
                                withAnimation {
                                    isWaitingWithSpinner = true
                                }
                                Task {
                                    let resp = await viewState.signInWithVerify(code: verifyCode, email: email, password: password)
                                    if !resp {
                                        withAnimation {
                                            isWaitingWithSpinner = false
                                            errorMessage = "Invalid verification code"
                                        }
                                        return
                                    }
                                    withAnimation {
                                        isSpinnerComplete = true
                                    }
                                    try! await Task.sleep(for: .seconds(2))
                                    withAnimation {
                                        isWaitingWithSpinner = false
                                        isSpinnerComplete = false
                                        onboardingStage = .Username
                                    }
                                }
                            }
                            else if onboardingStage == .Username {
                                if username.isEmpty {
                                    withAnimation {
                                        errorMessage = "Please enter a username"
                                    }
                                    return
                                }
                                errorMessage = nil
                                withAnimation {
                                    isWaitingWithSpinner = true
                                }
                                Task {
                                    do {
                                        _ = try await viewState.http.completeOnboarding(username: username).get()
                                    } catch {
                                        withAnimation {
                                            isWaitingWithSpinner = false
                                            errorMessage = "Invalid Username, try something else"
                                        }
                                        return
                                    }
                                    withAnimation {
                                        isSpinnerComplete = true
                                    }
                                    
                                    try! await Task.sleep(for: .seconds(2))
                                    viewState.isOnboarding = false
                                }
                            }
                        }) {
                            if isWaitingWithSpinner || isSpinnerComplete {
                                LoadingSpinnerView(frameSize: CGSize(width: 25, height: 25), isActionComplete: $isSpinnerComplete)
                            } else {
                                Text(onboardingStage == .Initial ? "Create Account" : onboardingStage == .Verify ? "Verify" : "Select Username")
                                    .font(.title2)
                            }
                        }
                        .padding(.vertical, 10)
                        .frame(width: isWaitingWithSpinner || isSpinnerComplete ? 100 : 250.0)
                        .foregroundStyle(.black)
                        .background(colorScheme == .light ? Color(white: 0.851) : Color.white)
                        .clipShape(.rect(cornerRadius: 50))
                    
                }
                if !isWaitingWithSpinner && onboardingStage == .Initial {
                    Spacer()
                }
            }
            .padding()
            
            if isWaitingWithSpinner && onboardingStage == .Initial {
                VStack {
                    HCaptchaView(apiKey: viewState.apiInfo!.features.captcha.key, baseURL: viewState.http.baseURL, result: $hCaptchaResult)
                        .onChange(of: hCaptchaResult) {
                            withAnimation {
                                isWaitingWithSpinner = false
                                isSpinnerComplete = true
                            }
                            Task {
                                do {
                                    _ = try await viewState.http.createAccount(email: email, password: password, invite: nil, captcha: hCaptchaResult).get()
                                } catch {
                                    withAnimation {
                                        isSpinnerComplete = false
                                        isWaitingWithSpinner = false
                                        errorMessage = "Sorry, your email or password was invalid"
                                    }
                                    return
                                }
                                try! await Task.sleep(for: .seconds(2))
                                withAnimation {
                                    isSpinnerComplete = false
                                    onboardingStage = .Verify
                                }
                            }
                    }
                }
            }
        }
        .onAppear {
            viewState.isOnboarding = true
        }
    }
}

#Preview {
    var viewState = ViewState.preview()
    
    return CreateAccount()
            .environmentObject(viewState)
}
