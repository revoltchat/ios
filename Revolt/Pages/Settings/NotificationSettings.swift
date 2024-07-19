//
//  NotificationSettings.swift
//  Revolt
//
//  Created by Angelo on 2024-02-10.
//

import SwiftUI
import Sentry

struct NotificationSettings: View {
    @EnvironmentObject var viewState: ViewState
    @State var pushNotificationsEnabled = false
    @State var notificationsWhileAppRunningEnabled = false
    
    var body: some View {
        List {
            Section("Push Notifications") {
                VStack {
                    CheckboxListItem(
                        title: "Enable push notifications",
                        isOn: $pushNotificationsEnabled,
                        onChange: { enabled in
                            if enabled {
                                Task {
                                    await viewState.promptForNotifications()
                                }
                            } else {
                                Task {
                                    do {
                                        let _ = try await viewState.http.revokeNotificationToken().get()
                                    } catch {
                                        SentrySDK.capture(error: error as! RevoltError)
                                        viewState.userSettingsStore.store.notifications.rejectedRemoteNotifications = false
                                        
                                        return
                                    }
                                    viewState.userSettingsStore.store.notifications.rejectedRemoteNotifications = true
                                    viewState.userSettingsStore.store.notifications.wantsNotificationsWhileAppRunning = false
                                    notificationsWhileAppRunningEnabled = false
                                }
                            }
                        })
                }
                VStack {
                    CheckboxListItem(
                        title: "Enable notifications while app running",
                        isOn: $notificationsWhileAppRunningEnabled,
                        onChange: { enabled in
                            viewState.userSettingsStore.store.notifications.wantsNotificationsWhileAppRunning = enabled
                        })
                    .disabled(!pushNotificationsEnabled)
                }
            }
            .listRowBackground(viewState.theme.background2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbarBackground(viewState.theme.topBar, for: .automatic)
        .scrollContentBackground(.hidden)
        .background(viewState.theme.background)
        
        .onAppear {
            pushNotificationsEnabled = !viewState.userSettingsStore.store.notifications.rejectedRemoteNotifications
            notificationsWhileAppRunningEnabled = viewState.userSettingsStore.store.notifications.wantsNotificationsWhileAppRunning
        }
    }
}

#Preview {
    NotificationSettings()
}
