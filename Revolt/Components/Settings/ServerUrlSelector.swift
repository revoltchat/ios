//
//  ServerUrlSelector.swift
//  Revolt
//
//  Created by pythcon on 12/7/24.
//

import SwiftUI
import Types

struct ServerUrlSelector: View {
    @EnvironmentObject var viewState: ViewState
    @Environment(\.colorScheme) var colorScheme
    
    private let officialServer = "https://api.revolt.chat"
    @State private var showCustomServer = false
    @State private var customDomain: String = ""
    @State private var isValidating = false
    @State private var validationError: String? = nil
    @State private var validationSuccess: String? = nil
    @State private var connectionStatus: ConnectionStatus = .untested
    @FocusState private var isTextFieldFocused: Bool
    
    enum ConnectionStatus {
        case untested
        case testing
        case success
        case failed
    }
    
    private func validateAndUpdateApiInfo(_ domain: String) {
        if domain.isEmpty { return }
        
        isValidating = true
        connectionStatus = .testing
        validationError = nil
        validationSuccess = nil
        
        let baseUrl: String
        if domain == officialServer {
            print("Using official server URL without /api")
            baseUrl = officialServer
        } else if domain.starts(with: "http://") || domain.starts(with: "https://") {
            baseUrl = (domain.hasSuffix("/") ? String(domain.dropLast()) : domain) + "/api"
        } else {
            baseUrl = "https://" + (domain.hasSuffix("/") ? String(domain.dropLast()) : domain) + "/api"
        }
        
        
        // Store the full base URL including protocol
        viewState.userSettingsStore.store.serverUrl = baseUrl
        
        // Set temporary HTTP client to validate
        let tempHttp = HTTPClient(token: nil, baseURL: baseUrl)
        
        Task {
            do {
                let fetchedApiInfo = try await tempHttp.fetchApiInfo().get()
                viewState.apiInfo = fetchedApiInfo
                
                isValidating = false
                validationSuccess = "Successfully connected to server"
                connectionStatus = .success
            } catch {
                isValidating = false
                validationError = "Unable to connect to server"
                connectionStatus = .failed
            }
        }
    }
    
    private var statusIcon: some View {
        Group {
            switch connectionStatus {
            case .untested:
                Image(systemName: "link.circle.fill")
                    .foregroundStyle(.gray)
            case .testing:
                ProgressView()
                    .controlSize(.small)
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .failed:
                Image(systemName: "x.circle.fill")
                    .foregroundStyle(.red)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Server")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: {
                    withAnimation {
                        showCustomServer.toggle()
                        if !showCustomServer {
                            validateAndUpdateApiInfo(officialServer)
                            viewState.userSettingsStore.store.serverUrl = officialServer
                        }
                    }
                }) {
                    Text(showCustomServer ? "Use Official" : "Use Custom")
                        .font(.caption)
                        .foregroundStyle(viewState.theme.accent)
                }
            }
            
            if showCustomServer {
                HStack {
                    TextField(
                        "Domain (e.g. example.com)",
                        text: $customDomain
                    )
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .disabled(isValidating)
                    .focused($isTextFieldFocused)
                    .onChange(of: isTextFieldFocused) { oldValue, newValue in
                        if !newValue {
                            validateAndUpdateApiInfo(customDomain)
                        }
                    }
                    .onChange(of: customDomain) { oldValue, newValue in
                        if oldValue != newValue {
                            connectionStatus = .untested
                            validationError = nil
                            validationSuccess = nil
                        }
                    }
                    
                    Button(action: {
                        if !customDomain.isEmpty {
                            validateAndUpdateApiInfo(customDomain)
                        }
                    }) {
                        statusIcon
                    }
                    .disabled(connectionStatus == .testing || customDomain.isEmpty)
                }
                .padding()
                .background((colorScheme == .light) ? Color(white: 0.851) : Color(white: 0.2))
                .clipShape(.rect(cornerRadius: 5))
                
                if let error = validationError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if let success = validationSuccess {
                    Text(success)
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            } else {
                Text("Official Revolt Server")
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background((colorScheme == .light) ? Color(white: 0.851) : Color(white: 0.2))
                    .clipShape(.rect(cornerRadius: 5))
            }
        }
        .padding(.bottom)
        .onAppear {
            if viewState.userSettingsStore.store.serverUrl.isEmpty {
                viewState.userSettingsStore.store.serverUrl = officialServer
                validateAndUpdateApiInfo(officialServer)
            }
        }
    }
}