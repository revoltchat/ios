//
//  AppDelegate.swift
//  Revolt
//
//  Created by Angelo on 2023-11-29.
//

import Foundation
import SwiftUI
import Sentry
import UserNotificationsUI

#if os(macOS)
import AppKit
#endif


#if os(iOS)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
        
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        ViewState.application = application
        return true
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        SentrySDK.capture(message: "Failed to register for remote notification. Error \(error)")
        // TODO: propagate to user?
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let state = ViewState.shared ?? ViewState()
        let token = deviceToken.reduce("", {$0 + String(format: "%02x", $1)})
        
        debugPrint("received notification token!")

        if state.http.token != nil {
            Task {
                debugPrint("uploading notification token")
                _ = await state.http.uploadNotificationToken(token: token)
            }
        } else {
            SentrySDK.capture(message: "Received notification token without available session token")
            fatalError("Received notification token without available session token")
        }
    }
}

#elseif os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
    }
    
    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notification. Error \(error)")
        // TODO: propagate to user?
    }

    func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let state = ViewState.shared ?? ViewState()
        let token = deviceToken.reduce("", {$0 + String(format: "%02x", $1)})

        if state.http.token != nil {
            Task {
                await state.http.uploadNotificationToken(token: token)
            }
        } else {
            SentrySDK.capture(message: "Received notification token without available session token")
            fatalError("Received notification token without available session token")
        }
    }
}
#endif

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let state = ViewState.shared ?? ViewState()

        if state.sessionToken == nil {
            return
        }
        
        let userinfo = response.notification.request.content.userInfo
        state.currentChannel = .channel(userinfo["channelId"] as! String)
        state.currentServer = .server(userinfo["serverId"] as! String)
        // TODO: scroll to message

    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // TODO: handle notification taps while app is running
        completionHandler([.list, .banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        print("notification settings")
        guard let notification = notification else {return} // TODO: app-wide settings?
        
        let state = ViewState.shared ?? ViewState()
        if state.sessionToken == nil {
            return
        }
        // per-channel notification settings should open here
    }
}
