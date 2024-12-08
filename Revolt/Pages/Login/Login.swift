import SwiftUI
import Types


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
                ServerUrlSelector()
                
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

            NavigationLink("Resend a verification email", destination: { ResendEmail() })
                .padding(15)
            
            NavigationLink("Forgot Password", destination: { ForgotPassword() })
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
    @State var error: String? = nil
    
    @FocusState var textEntryFocus: String?

    @Environment(\.colorScheme) var colorScheme: ColorScheme

    func getMethodDetails(method: String) -> (String, String, String, String, UIKeyboardType) {
        switch method {
            case "Password":
                return ("lock.fill", "Enter a password", "Enter your saved password.", "Password", .default)
            case "Totp":
                return ("checkmark", "Enter a six-digit code", "Enter the six-digit code from your authenticator app", "Code", .numberPad)
            case "Recovery":
                return ("arrow.counterclockwise", "Enter a recovery code", "Enter your backup recovery code", "Recovery code", .default)
            default:
                return ("questionmark", "Unknown", "Unknown", "Unknown", .default)
        }
    }
    
    func sendMfa() {
        let key: String
        
        switch selected {
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
                    case .Disabled:
                        error = "Account disabled"
                    case .Invalid:
                        error = "Invalid \(selected!.replacing("_", with: " "))"
                    case .Onboarding:
                        ()
                    case .Mfa(let ticket, let methods):
                        self.ticket = ticket
                        self.methods = methods
                        error = "Please try again"
                }
            })
        }
    }
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .center, spacing: 16) {
                Spacer()
                
                Text("One more thing")
                    .bold()
                    .font(.title)
                
                Spacer()
                
                Text("You've got 2FA enabled to keep your account extra-safe.")
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if let error {
                    Text(verbatim: error)
                        .foregroundStyle(.red)
                }
                
                ScrollView {
                    ForEach(methods, id: \.self) { method in
                        let (icon, text, desc, placeholder, keyboardType) = getMethodDetails(method: method)
                        
                        VStack(alignment: .leading) {
                            Button {
                                withAnimation {
                                    if selected == method {
                                        selected = nil
                                        textEntryFocus = nil
                                    } else {
                                        selected = method
                                        textEntryFocus = method
                                    }
                                    
                                    currentText = ""
                                }
                            } label: {
                                VStack(alignment: .center, spacing: 12) {
                                    HStack(alignment: .center, spacing: 16) {
                                        
                                        Image(systemName: icon)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 24)
                                        
                                        Text(text)
                                            .bold()
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.down")
                                    }
                                    
                                    if selected == method {
                                        Text(desc)
                                            .foregroundStyle(.secondary)
                                        
                                        VStack(alignment: .leading, spacing: 16) {
                                            TextField(placeholder, text: $currentText)
                                                .focused($textEntryFocus, equals: method)
                                            #if os(iOS)
                                                .keyboardType(keyboardType)
                                            #endif
                                                .textContentType(.oneTimeCode)
                                                .onSubmit(sendMfa)
                                            
                                            Button {
                                                sendMfa()
                                            } label: {
                                                HStack {
                                                    Spacer()
                                                    Text("Next")
                                                    Spacer()
                                                }
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .buttonBorderShape(.roundedRectangle(radius: 8))
                                            .tint(.themePrimary)
                                        }
                                    }
                                }
                                .padding(.horizontal, 32)
                                .padding(.vertical, 16)
                            }
                            .background(RoundedRectangle(cornerRadius: 8)
                                .foregroundStyle(.gray.opacity(0.2))
                            )
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
