import SwiftUI

struct Login: View {
    @State private var stack = NavigationPath()

    var body: some View {
        NavigationStack(path: $stack) {
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
                    NavigationLink("Log In", destination: LogIn(stack: stack))
                        .padding(.vertical, 10)
                        .frame(width: 200.0)
                        .background(.black)
                        .foregroundColor(.white)
                        .cornerRadius(50)

                    NavigationLink("Sign Up", destination: SignUp())
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
        }
    }
}

struct LogIn: View {
    @EnvironmentObject var viewState: ViewState

    @State var stack: NavigationPath

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showMfa = false
    @State private var mfaTicket = ""
    @State private var mfaMethods: [String] = []
    @State private var errorMessage: String? = nil

    @FocusState private var focus1: Bool
    @FocusState private var focus2: Bool

    private func logIn() async {
        await viewState.signIn(email: email, password: password, callback: { state in
            print(state)

            switch state {
                case .Mfa(let ticket, let methods):
                    self.mfaTicket = ticket
                    self.mfaMethods = methods
                    self.stack.append("mfa")

                case .Disabled:
                    self.errorMessage = "Account has been disabled."
                    
                case .Success:
                    stack.removeLast(stack.count)
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
                if (errorMessage != nil) {
                    Text(errorMessage!).foregroundColor(.red)
                }
                TextField(
                    "Email",
                    text: $email
                )
                    .padding()
                    .background(Color(white: 0.851))
                    .cornerRadius(5)

                ZStack(alignment: .trailing) {
                    TextField(
                        "Password",
                        text: $password
                    )
                        .padding()
                        .background(Color(white: 0.851))
                        .cornerRadius(5)
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
                        .cornerRadius(5)
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
                    .navigationDestination(for: String.self) { _ in
                        Mfa(ticket: mfaTicket, methods: mfaMethods)
                    }
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
                .cornerRadius(50)

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
    var ticket: String
    var methods: [String]
    
    var body: some View {
        Text("mfa")
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
