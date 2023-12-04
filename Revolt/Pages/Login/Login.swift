import SwiftUI


struct LogIn: View {
    @EnvironmentObject var viewState: ViewState

    @Binding var path: NavigationPath

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showMfa = false
    @State private var errorMessage: String? = nil
    
    @State private var needsOnboarding = false

    @Binding public var mfaTicket: String
    @Binding public var mfaMethods: [String]

    @FocusState private var focus1: Bool
    @FocusState private var focus2: Bool
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    private func logIn() async {
        await viewState.signIn(email: email, password: password, callback: { state in
            switch state {
                case .Mfa(let ticket, let methods):
                    self.mfaTicket = ticket
                    self.mfaMethods = methods
                    self.path.append("mfa")

                case .Disabled:
                    self.errorMessage = "Account has been disabled."

                case .Success:
                    path = NavigationPath()
                
                case .Invalid:
                    self.errorMessage = "Invalid email and/or password"
                
                case .Onboarding:
                    viewState.isOnboarding = true
                    self.needsOnboarding = true
            }
        })
    }

    var body: some View {
        VStack {
            Spacer()

            Text("Let's log you in")
                .font(.title)
                .fontWeight(.bold)
                .padding()
                .foregroundStyle((colorScheme == .light) ? Color.black : Color.white)

            Group {
                if let error = errorMessage {
                    Text(verbatim: error)
                        .foregroundStyle(.red)
                }

                TextField(
                    "Email",
                    text: $email
                )
                    #if os(iOS)
                    .keyboardType(.emailAddress)
                    #endif
                    .textContentType(.emailAddress)
                    .padding()
                    .background((colorScheme == .light) ? Color(white: 0.851) : Color(white: 0.2))
                    .clipShape(.rect(cornerRadius: 5))
                    .foregroundStyle((colorScheme == .light) ? Color.black : Color.white)

                ZStack(alignment: .trailing) {
                    TextField(
                        "Password",
                        text: $password
                    )
                        .textContentType(.password)
                        .padding()
                        .background((colorScheme == .light) ? Color(white: 0.851) : Color(white: 0.2))
                        .clipShape(.rect(cornerRadius: 5))
                        .modifier(PasswordModifier())
                        .textContentType(.password)
                        .foregroundStyle((colorScheme == .light) ? Color.black : Color.white)
                        .opacity(showPassword ? 1 : 0)
                        .focused($focus1)

                    SecureField(
                        "Password",
                        text: $password
                    )
                        .textContentType(.password)
                        .padding()
                        .background((colorScheme == .light) ? Color(white: 0.851) : Color(white: 0.2))
                        .clipShape(.rect(cornerRadius: 5))
                        .modifier(PasswordModifier())
                        .textContentType(.password)
                        .foregroundStyle((colorScheme == .light) ? Color.black : Color.white)
                        .opacity(showPassword ? 0 : 1)
                        .focused($focus2)

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

            Spacer()

            Button(action: { Task { await logIn() } }) {
                Text("Log In")
            }
                .padding(.vertical, 10)
                .frame(width: 200.0)
                .foregroundStyle(.black)
                .background(Color(white: 0.851))
                .clipShape(.rect(cornerRadius: 50))

            Spacer()

            NavigationLink("Resend a verification email", destination: ResendEmail())
                .padding(15)
            
            NavigationLink("Forgot Password", destination: ForgotPassword())
                .padding(15)

            Spacer()
        }
        .padding()
        .navigationDestination(isPresented: $needsOnboarding) { // we dont use a link+destination because this will overlay when the user hasn't onboarded
            CreateAccount(onboardingStage: .Username)
        }
    }
}

struct Mfa: View {
    @EnvironmentObject var viewState: ViewState

    @Binding public var path: NavigationPath
    @Binding var ticket: String
    @Binding var methods: [String]

    @State var selected: String? = nil
    @State var currentText: String = ""

    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    var body: some View {
        VStack {
            Spacer()
    
            Text("One more thing")
                .font(.title)
            
            Spacer()

            Text("You've got 2FA enabled to keep your account extra-safe.")

            Spacer()
        
            List(methods, id: \.self) { method in
                Button(action: {
                    withAnimation {
                        if selected == method {
                            selected = nil
                        } else {
                            selected = method
                        }
                        
                        currentText = ""
                    }
                }, label: {
                    VStack(alignment: .leading) {
                        HStack(alignment: .top) {
                            Text("use a \(method.lowercased()) code")
                                .frame(alignment: .center)
                        }
                        
                        if selected == method {
                            ZStack(alignment: .trailing) {
                                TextField("\(method.lowercased()) code", text: $currentText)
                                Button("enter", systemImage: "arrowshape.right.circle") {
                                    let key: String
                                    
                                    switch method {
                                        case "Password":
                                            key = "password"
                                        case "Totp":
                                            key = "totp_code"
                                        case "Recovery":
                                            key = "recovery_code"
                                        case _:
                                            return
                                    }
                                    
                                    Task {
                                        await viewState.signIn(mfa_ticket: ticket, mfa_response: [key: currentText], callback: { response in
                                            switch response {
                                                case .Success:
                                                    path = NavigationPath()
                                                case _:
                                                    ()
                                            }
                                        })
                                    }
                                }
                                .labelStyle(.iconOnly)
                            }
                        }
                    }
                    .transition(.slide)
                    .animation(.easeInOut, value: currentText)
                })
            }
        }
        .foregroundColor((colorScheme == .light) ? Color.black : Color.white)
    }
}

struct PasswordModifier: ViewModifier {
    var borderColor: Color = Color.gray

    func body(content: Content) -> some View {
        content
            .disableAutocorrection(true)
    }
}



#Preview {
    LogIn(path: .constant(NavigationPath()), mfaTicket: .constant(""), mfaMethods: .constant([]))
        .environmentObject(ViewState.preview())
}
