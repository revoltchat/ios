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

func declareNotificationCategoryTypes() {
    // first: messages
    let replyAction = UNTextInputNotificationAction(identifier: "REPLY", title: "Reply", options: [.authenticationRequired], textInputButtonTitle: "Done", textInputPlaceholder: "Reply to this message...")
    let messageCategory = UNNotificationCategory(identifier: "ALERT_MESSAGE", actions: [replyAction], intentIdentifiers: [], options: [])
    
    let notificationCenter = UNUserNotificationCenter.current()
    notificationCenter.setNotificationCategories([messageCategory])
}

#if os(iOS)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
        
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        ViewState.application = application
        declareNotificationCategoryTypes()
        return true
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        SentrySDK.capture(message: "Failed to register for remote notification. Error \(error)")
        // TODO: propagate to user?
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let state = ViewState.shared ?? ViewState()
        let token = deviceToken.reduce("", {$0 + String(format: "%02x", $1)})
        
        debugPrint("received notification token: \(token)")

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
        declareNotificationCategoryTypes()
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
    /*func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let state = ViewState.shared ?? ViewState()

        if state.sessionToken == nil {
            return
        }
        
        
        
        let userinfo = response.notification.request.content.userInfo
        state.currentChannel = .channel(userinfo["channelId"] as! String)
        state.currentServer = .server(userinfo["serverId"] as! String)
        // TODO: scroll to message

    }*/
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let state = ViewState.shared ?? ViewState()

        if state.sessionToken == nil {
            return
        }
        
        let userinfo = response.notification.request.content.userInfo
        let channelId = (userinfo["message"] as! [String: Any])["channel"] as! String
        let serverId = userinfo["serverId"] as! String
        let messageId = (userinfo["message"] as! [String: Any])["_id"] as! String
        
        print(response.actionIdentifier)
        debugPrint(response)
        
        switch response.actionIdentifier {
        case "REPLY":
            let response = response as! UNTextInputNotificationResponse
            Task {
                await state.http.sendMessage(channel: channelId, replies: [ApiReply(id: messageId, mention: false)], content: response.userText, attachments: [], nonce: "")
            }
        default:
            state.currentChannel = .channel(channelId)
            state.currentServer = .server(serverId)
        }
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
