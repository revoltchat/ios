//
//  Welcome.swift
//  Revolt
//
//  Created by Angelo Manca on 2023-11-15.
//

import SwiftUI
import Types

struct Welcome: View {
    @EnvironmentObject var viewState: ViewState
    @State private var path = NavigationPath()
    @State private var mfaTicket = ""
    @State private var mfaMethods: [String] = []

    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                Spacer()
                Group {
                    Image("wide")
                        .if(colorScheme == .light, content: { $0.colorInvert() })
                        .padding(.bottom, 20)

                    Text("Find your community, connect with the world.")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .foregroundColor((colorScheme == .light) ? Color.black : Color.white)

                    Text("Revolt is one of the best ways to stay connected with your friends and community, anywhere, anytime.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 55.0)
                        .padding(.top, 10.0)
                        .font(.footnote)
                        .foregroundColor((colorScheme == .light) ? Color.black : Color.white)
                }

                Spacer()

                Group {
                    NavigationLink("Log In", value: "login")
                        .padding(.vertical, 10)
                        .frame(width: 200.0)
                        .background((colorScheme == .light) ? Color.black : Color.white)
                        .foregroundColor((colorScheme == .light) ? Color.white : Color.black)
                        .cornerRadius(50)

                    NavigationLink("Sign Up", value: "signup")
                        .padding(.vertical, 10)
                        .frame(width: 200.0)
                        .foregroundColor(.black)
                        .background((colorScheme == .light) ? Color(white: 0.851) : Color(white: 0.4))
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
                switch dest {
                    case "mfa":
                        Mfa(path: $path, ticket: $mfaTicket, methods: $mfaMethods)
                    case "login":
                        LogIn(path: $path, mfaTicket: $mfaTicket, mfaMethods: $mfaMethods)
                    case "signup":
                        CreateAccount()
                    case _:
                        EmptyView()
                }

            }
        }
        .onAppear {
            viewState.isOnboarding = false
        }
        .task {
            viewState.apiInfo = try? await viewState.http.fetchApiInfo().get()
        }
    }
}

#Preview {
    Welcome()
        .environmentObject(ViewState.preview())
}
