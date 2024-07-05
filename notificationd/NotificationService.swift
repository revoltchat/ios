//
//  NotificationService.swift
//  notificationd
//
//  Created by Angelo on 2024-07-04.
//

import UserNotifications
import Intents
import Types
import os

func getMessageIntent(_ notification: UNNotificationContent) -> INSendMessageIntent? {
    let info = notification.userInfo
    
    // You can't go from a dictionary to a model without some really stupid workarounds that are annoyingly verbose,
    // so instead we'll just serialize to json and then back out to the model.
    // I hate it here.
    let data = try? JSONSerialization.data(withJSONObject: info["message"] as Any, options: [])
    guard let data = data else { return nil }
    
    let message = try? JSONDecoder().decode(Message.self, from: data)
    guard let message = message else { return nil }
    
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
    
    let intent = INSendMessageIntent(
        recipients: nil,
        outgoingMessageType: .outgoingMessageText,
        content: message.content,
        speakableGroupName: speakableGroupName,
        conversationIdentifier: message.channel,
        serviceName: nil,
        sender: sender,
        attachments: nil
    )
    
    // TODO: figure out how to manually set avatars (for dm groups)
    //intent.setImage(avatar, forParameterNamed: NSString("speakableGroupName"))
    
    return intent
}

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) async {
        let logger = Logger(subsystem: "app.revolt.chat", category: "notificationd")
        logger.info("Invoked notification extension")
        
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as! UNMutableNotificationContent)
        bestAttemptContent!.title = "beans"
        
        if request.content.categoryIdentifier != "ALERT_MESSAGE" {
            bestAttemptContent!.subtitle = "not an alert message"
            contentHandler(bestAttemptContent!)
            return
        }
        
        let intent = getMessageIntent(request.content)
        guard let intent = intent else {
            bestAttemptContent!.subtitle = "Failed to receive intent"
            contentHandler(bestAttemptContent!)
            return
        }
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.direction = .incoming
        
        do {
            try await interaction.donate()
            
            let updated = try bestAttemptContent!.updating(from: intent)
            contentHandler(updated)
            
        } catch {
            bestAttemptContent!.subtitle = error.localizedDescription
            contentHandler(bestAttemptContent!)
            return
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
