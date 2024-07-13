//
//  NotificationService.swift
//  NotificationService
//
//  Created by Angelo Manca on 2024-07-12.
//

import UserNotifications
import os
import Intents
import Types

let logger = Logger(subsystem: "app.revolt.chat", category: "notificationd")


func getMessageIntent(_ notification: UNNotificationContent) -> INSendMessageIntent? {
    let info = notification.userInfo
    
    // You can't go from a dictionary to a model without some really stupid workarounds that are annoyingly verbose,
    // so instead we'll just serialize to json and then back out to the model.
    // I hate it here.
    let data = try? JSONSerialization.data(withJSONObject: info["message"] as Any, options: [])
    guard let data = data else { return nil }
    
    let message = try? JSONDecoder().decode(Message.self, from: data)
    guard let message = message else { return nil }
    
    #if DEBUG
    debugPrint(message)
    #endif
    
    let handle = INPersonHandle(value: message.author, type: .unknown)
    let avatar = INImage(url: URL(string: info["authorAvatar"] as! String)!)
    let sender = INPerson(
        personHandle: handle,
        nameComponents: nil,
        displayName: info["authorDisplayName"] as? String,
        image: avatar,
        contactIdentifier: nil,
        customIdentifier: nil
    )
    
    var speakableGroupName: INSpeakableString? = nil
    if let groupName = info["channelName"] as? String {
        speakableGroupName = INSpeakableString(spokenPhrase: groupName)
    }
    
    let displayedAttachment: INSendMessageAttachment? = nil
    
    if let attachments = message.attachments {
        //TODO: we need to get the instance config here to know what the URL is.
        // That means we need to use an app group to share files between the app and the service extension,
        // and save the instance config to disk.
        // The instance config doesn't need to be encrypted since it's public info.
    }
    
    let intent = INSendMessageIntent(
        recipients: nil,
        outgoingMessageType: .outgoingMessageText,
        content: message.content,
        speakableGroupName: speakableGroupName,
        conversationIdentifier: message.channel,
        serviceName: nil,
        sender: sender,
        attachments: displayedAttachment
    )
        
    // TODO: figure out how to manually set avatars (for dm groups)
    //intent.setImage(avatar, forParameterNamed: NSString("speakableGroupName"))
    
    return intent
}

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        #if DEBUG
        logger.trace("Invoked service extension")
        debugPrint(request)
        #endif
        
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            if request.content.categoryIdentifier != "ALERT_MESSAGE" {
                #if DEBUG
                logger.debug("recieved non-alert-message with cateogry: \(request.content.categoryIdentifier)")
                #endif
                
                contentHandler(bestAttemptContent)
                return
            }
            
            let intent = getMessageIntent(request.content)
            guard let intent = intent else {
                #if DEBUG
                logger.debug("Failed to receive the intent.")
                #endif
                contentHandler(bestAttemptContent)
                return
            }
            let interaction = INInteraction(intent: intent, response: nil)
            interaction.direction = .incoming
            
            do {
                try interaction.donate()
                
                let originalTitle = bestAttemptContent.title
                let updated = try bestAttemptContent.updating(from: intent)
                updated.title = originalTitle // we actually dont want the title from the intent, since it's just the username
                
                contentHandler(updated)
                
            } catch {
                logger.error("\(error.localizedDescription)")
                bestAttemptContent.subtitle = error.localizedDescription
                contentHandler(bestAttemptContent)
                return
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
