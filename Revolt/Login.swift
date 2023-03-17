//
//  Login.swift
//  Revolt
//
//  Created by Zomatree on 17/03/2023.
//

import SwiftUI

struct Login: View {
    func logIn() {

    }

    func signUp() {

    }

    var body: some View {
        NavigationStack {
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
                    NavigationLink("Log In", destination: LogIn())
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
    @State private var email = ""
    @State private var password = ""

    private func logIn() {
        print("\(email) \(password)")
    }

    var body: some View {
        VStack {
            Spacer()

            Text("Let's log you in")
                .font(.title)
                .fontWeight(.bold)
                .padding()

            Group {
                TextField(
                    "Email",
                    text: $email
                )
                TextField(
                    "Password",
                    text: $password
                )
                NavigationLink("Forgot password?", destination: ResendEmail())
            }
            .padding()

            Spacer()

            Button(action: logIn) {
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
