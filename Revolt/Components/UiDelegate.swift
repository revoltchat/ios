//
//  UiDelegate.swift
//  Revolt
//
//  Created by Angelo on 2023-11-29.
//

import Foundation
import SwiftUI
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
        return true
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notification. Error \(error)")
        // TODO: propagate to user?
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let state = ViewState.shared ?? ViewState()
        let token = deviceToken.reduce("", {$0 + String(format: "%02x", $1)})

        print("Device token: \(token)")
        if state.http.token != nil {
            Task {
                await state.http.uploadWebPushToken(token: token)
            }
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

        print("Device token: \(token)")
        if state.http.token != nil {
            Task {
                await state.http.uploadWebPushToken(token: token)
            }
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
        state.currentChannel = .channel(userinfo["channelID"] as! String)
        state.currentServer = .server(userinfo["serverID"] as! String)
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
