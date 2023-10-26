import SwiftUI

struct Login: View {
    @State private var path = NavigationPath()
    @State private var mfaTicket = ""
    @State private var mfaMethods: [String] = []

    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                Spacer()
                Group {
                    Image("wide")
                        .colorInvert()
                        .padding(.bottom, 20)
                    Text("Find your community, connect with the world.")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Text("Revolt is one of the best ways to stay connected with your friends and community, anywhere, anytime.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 55.0)
                        .padding(.top, 10.0)
                        .font(.footnote)
                }

                Spacer()

                Group {
                    NavigationLink("Log In", value: "login")
                        .padding(.vertical, 10)
                        .frame(width: 200.0)
                        .background(.black)
                        .foregroundColor(.white)
                        .cornerRadius(50)

                    NavigationLink("Sign Up", value: "signup")
                        .padding(.vertical, 10)
                        .frame(width: 200.0)
                        .foregroundColor(.black)
                        .background(Color(white: 0.851))
                        .cornerRadius(50)
                }

                Spacer()

                Group {
                    Link("Terms of Service", destination: URL(string: "https://revolt.chat/terms")!)
                        .font(.footnote)
                        .foregroundColor(Color(white: 0.584))
                    Link("Privacy Policy", destination: URL(string: "https://revolt.chat/privacy")!)
                        .font(.footnote)
                        .foregroundColor(Color(white: 0.584))
                    Link("Community Guidelines", destination: URL(string: "https://revolt.chat/aup")!)
                        .font(.footnote)
                        .foregroundColor(Color(white: 0.584))
                }
            }
            .navigationDestination(for: String.self) { dest in
                let _ = print(dest)

                switch dest {
                    case "mfa":
                        Mfa(path: $path, ticket: $mfaTicket, methods: $mfaMethods)
                    case "login":
                        LogIn(path: $path, mfaTicket: $mfaTicket, mfaMethods: $mfaMethods)
                    case "signup":
                        SignUp()
                    case _:
                        EmptyView()
                }

            }
        }
    }
}

struct LogIn: View {
    @EnvironmentObject var viewState: ViewState

    @Binding var path: NavigationPath

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showMfa = false
    @State private var errorMessage: String? = nil

    @Binding public var mfaTicket: String
    @Binding public var mfaMethods: [String]

    @FocusState private var focus1: Bool
    @FocusState private var focus2: Bool

    private func logIn() async {
        await viewState.signIn(email: email, password: password, callback: { state in
            print(state)

            switch state {
                case .Mfa(let ticket, let methods):
                    print(self.path)
                    self.mfaTicket = ticket
                    self.mfaMethods = methods
                    self.path.append("mfa")

                case .Disabled:
                    self.errorMessage = "Account has been disabled."

                case .Success:
                    path = NavigationPath()
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

            Group {
                if let error = errorMessage {
                    Text(error)
                }
                TextField(
                    "Email",
                    text: $email
                )
                    .padding()
                    .background(Color(white: 0.851))
                    .clipShape(.rect(cornerRadius: 5))

                ZStack(alignment: .trailing) {
                    TextField(
                        "Password",
                        text: $password
                    )
                        .padding()
                        .background(Color(white: 0.851))
                        .clipShape(.rect(cornerRadius: 5))
                        .modifier(PasswordModifier())
                        .textContentType(.password)
                        .opacity(showPassword ? 1 : 0)
                        .focused($focus1)

                    SecureField(
                        "Password",
                        text: $password
                    )
                        .padding()
                        .background(Color(white: 0.851))
                        .clipShape(.rect(cornerRadius: 5))
                        .modifier(PasswordModifier())
                        .textContentType(.password)
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
                        Image(systemName: self.showPassword ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 16, weight: .regular))
                            .padding()
                    })
                }

                NavigationLink("Forgot password?", destination: ResendEmail())
            }
            .padding()

            Spacer()

            Button(action: { Task { await logIn() } }) {
                Text("Log In")
            }
                .padding(.vertical, 10)
                .frame(width: 200.0)
                .foregroundColor(.black)
                .background(Color(white: 0.851))
                .clipShape(.rect(cornerRadius: 50))

            Spacer()

            Group {
                NavigationLink("Resend a verification email", destination: ResendEmail())
                NavigationLink("Using a password manager?", destination: ResendEmail())
            }

            Spacer()
        }
        .padding()
    }
}

struct Mfa: View {
    @EnvironmentObject var viewState: ViewState

    @Binding public var path: NavigationPath
    @Binding var ticket: String
    @Binding var methods: [String]

    @State var selected: String? = nil
    @State var currentText: String = ""

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
    }
}

struct PasswordModifier: ViewModifier {
    var borderColor: Color = Color.gray

    func body(content: Content) -> some View {
        content
            .disableAutocorrection(true)
    }
}

struct SignUp: View {
    var body: some View {
        Text("Sign up here")
    }
}

struct ResendEmail: View {
    var body: some View {
        Text("resend email")
    }
}

struct Login_Previews: PreviewProvider {
    static var previews: some View {
        Login()
    }
}
