//
//  UserSettingsStore.swift
//  Revolt
//
//  Created by Angelo on 2024-02-23.
//

import Foundation
import Observation
import OSLog
import Sentry
import Types

let logger = Logger(subsystem: "chat.revolt.app", category: "settingsStore")


// MARK: - Discardable caches

struct AccountSettingsMFAStatus: Codable {
    var email_otp: Bool
    var trusted_handover: Bool
    var email_mfa: Bool
    var totp_mfa: Bool
    var security_key_mfa: Bool
    var recovery_active: Bool
    
    var anyMFA: Bool {
        return email_otp || totp_mfa || recovery_active || email_mfa || security_key_mfa || trusted_handover
    }
}

struct UserSettingsAccountData: Codable {
    var email: String
    var mfaStatus: AccountSettingsMFAStatus
}

enum NotificationState: String, Encodable {
    case all, mention, muted, none
}

extension NotificationState: Decodable {
    enum Inner: String, Decodable {
        case all, mention, muted, none
    }
    
    init(from decoder: any Decoder) throws {
        do {
            switch try decoder.singleValueContainer().decode(Inner.self) {
                case .all: self = .all
                case .mention: self = .mention
                case .muted: self = .muted
                case .none: self = .none
            }
        } catch {
            self = .all
        }
    }
}


struct UserSettingsNotificationsData: Codable {
    var server: [String: NotificationState]
    var channel: [String: NotificationState]
}

@Observable
class DiscardableUserStore: Codable {
    var user: Types.User?
    var accountData: UserSettingsAccountData?
    var notificationSettings: UserSettingsNotificationsData = .init(server: [:], channel: [:])
    
    /// This is null when we havent asked for permission yet
    fileprivate func clear() {
        user = nil
        accountData = nil
        notificationSettings = .init(server: [:], channel: [:])
    }
    
    enum CodingKeys: String, CodingKey {
        case _user = "user"
        case _accountData = "accountData"
        case _notificationSettings = "notificationSettings"
    }
}

// MARK: - Persistent settings

@Observable
class NotificationOptionsData: Codable {
    var keyWasSet: () -> Void = {}
    
    var rejectedRemoteNotifications: Bool {
        didSet(newSetting) {
            keyWasSet()
        }
    }
    
    var wantsNotificationsWhileAppRunning: Bool {
        didSet(newSetting) {
            keyWasSet()
        }
    }
    
    init(keyWasSet: @escaping () -> Void, rejectedRemoteNotifications: Bool, wantsNotificationsWhileAppRunning: Bool) {
        self.rejectedRemoteNotifications = rejectedRemoteNotifications
        self.wantsNotificationsWhileAppRunning = wantsNotificationsWhileAppRunning

        self.keyWasSet = keyWasSet
    }
    
    init(keyWasSet: @escaping () -> Void) {
        self.rejectedRemoteNotifications = true
        self.wantsNotificationsWhileAppRunning = true
        
        self.keyWasSet = keyWasSet
    }
    
    init() {
        self.rejectedRemoteNotifications = true
        self.wantsNotificationsWhileAppRunning = true
    }
    
    enum CodingKeys: String, CodingKey {
        case _rejectedRemoteNotifications = "rejectedRemoteNotifications"
        case _wantsNotificationsWhileAppRunning = "wantsNotificationsWhileAppRunning"
    }
}

@Observable
class ExperimentOptionsData: Codable {
    var keyWasSet: () -> Void = {}
    
    var customMarkdown: Bool {
        didSet(newSetting) {
            keyWasSet()
        }
    }
    
    init(keyWasSet: @escaping () -> Void, customMarkdown: Bool) {
        self.customMarkdown = customMarkdown
        
        self.keyWasSet = keyWasSet
    }
    
    init(keyWasSet: @escaping () -> Void) {
        customMarkdown = false
        
        self.keyWasSet = keyWasSet
    }
    
    init() {
        self.customMarkdown = false
    }
    
    enum CodingKeys: String, CodingKey {
        case _customMarkdown = "customMarkdown"
    }
}

@Observable
class PersistentUserSettingsStore: Codable {
    var keyWasSet: () -> Void = {}
    
    var notifications: NotificationOptionsData
    
    var lastOpenChannels: [String: String] {
        didSet {
            keyWasSet()
        }
    }
    
    var closedCategories: [String: Set<String>] {
        didSet {
            keyWasSet()
        }
    }
    
    var experiments: ExperimentOptionsData

    init(keyWasSet: @escaping () -> Void, notifications: NotificationOptionsData, lastOpenChannels: [String: String], closedCategories: [String: Set<String>], experiments: ExperimentOptionsData) {
        self.notifications = notifications
        self.lastOpenChannels = lastOpenChannels
        self.closedCategories = closedCategories
        self.experiments = experiments
        
        self.keyWasSet = keyWasSet
    }
    
    init() {
        self.notifications = NotificationOptionsData()
        self.lastOpenChannels = [:]
        self.closedCategories = [:]
        self.experiments = ExperimentOptionsData()
    }
    
    fileprivate func updateDecodeWithCallback(keyWasSet: @escaping () -> Void) {
        self._notifications.keyWasSet = keyWasSet
        self._experiments.keyWasSet = keyWasSet
        self.keyWasSet = keyWasSet
    }
    
    enum CodingKeys: String, CodingKey {
        case _notifications = "notifications"
        case _lastOpenChannels = "lastOpenChannels"
        case _closedCategories = "closedCategories"
        case _experiments = "experiments"
    }
}

class UserSettingsData {
    enum SettingsFetchState {
        case fetching, failed, cached
    }
    
    var viewState: ViewState?
    
    var cache: DiscardableUserStore
    var cacheState: SettingsFetchState
    
    var store: PersistentUserSettingsStore
    
    static var cacheFile: URL? {
        if let caches = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let revoltDir = caches.appendingPathComponent(Bundle.main.bundleIdentifier!, conformingTo: .directory)
            let resp = revoltDir.appendingPathComponent("userInfoCache", conformingTo: .json)
            return resp
        }
        return nil
    }
    
    static var storeFile: URL? {
        if let caches = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let revoltDir = caches.appendingPathComponent(Bundle.main.bundleIdentifier!, conformingTo: .directory)
            let resp = revoltDir.appendingPathComponent("userSettings", conformingTo: .json)
            return resp
        }
        return nil
    }

    init(viewState: ViewState?, cache: DiscardableUserStore, store: PersistentUserSettingsStore) {
        self.viewState = viewState
        self.cache = cache
        self.cacheState = .cached
        self.store = store
        self.store.updateDecodeWithCallback(keyWasSet: storeKeyWasSet)
    }
    
    init(viewState: ViewState?, store: PersistentUserSettingsStore) {
        self.viewState = viewState
        self.cache = DiscardableUserStore()
        self.cacheState = .fetching
        
        self.store = store
        self.store.updateDecodeWithCallback(keyWasSet: storeKeyWasSet)
        
        createFetchTask()
    }
    
    init(viewState: ViewState?) {
        self.viewState = viewState
        self.cache = DiscardableUserStore()
        self.cacheState = .fetching
        
        self.store = PersistentUserSettingsStore()
        self.store.updateDecodeWithCallback(keyWasSet: storeKeyWasSet)
        
        createFetchTask()
    }
    
    class func maybeRead(viewState: ViewState?) -> UserSettingsData {
        var cache: DiscardableUserStore? = nil
        var store: PersistentUserSettingsStore? = nil
        
        var fileContents: Data?
        do {
            let filePath = UserSettingsData.cacheFile!
            fileContents = try Data(contentsOf: filePath)
        } catch {
            logger.debug("settingsCache file does not exist, will rebuild. \(error.localizedDescription)")
        }
        
        do {
            if fileContents != nil {
                cache = try JSONDecoder().decode(DiscardableUserStore.self, from: fileContents!)
            }
        } catch {
            logger.warning("Failed to parse the existing cache file. Will discard cache and rebuild. \(error.localizedDescription)")
        }
        
        var storefileContents: Data? = nil
        do {
            let filePath = UserSettingsData.storeFile!
            storefileContents = try Data(contentsOf: filePath)
        } catch {
            logger.warning("User settings have been removed. Will rebuild from scratch. \(error.localizedDescription)")
        }
        
        do {
            if storefileContents != nil {
                store = try JSONDecoder().decode(PersistentUserSettingsStore.self, from: storefileContents!)
            }
        } catch {
            logger.warning("Failed to parse the existing settings store file. Settings may have been lost. \(error.localizedDescription)")
        }
        
        if store != nil && cache != nil {
            return UserSettingsData(viewState: viewState, cache: cache!, store: store!)
        } else if store != nil {
            return UserSettingsData(viewState: viewState, store: store!)
        } else {
            return UserSettingsData(viewState: viewState)
        }
    }
    
    private func storeKeyWasSet() {
        DispatchQueue.main.async(qos: .utility) {
            self.writeStoreToFile()
        }
    }
    
    func createFetchTask() {
        Task(priority: .medium, operation: self.fetchFromApi)
    }
    
    func fetchFromApi() async {
        while viewState == nil {
            try! await Task.sleep(for: .seconds(0.1))
        }
        let state = viewState!
        if await state.state == .signedOut {
            return
        }
        
        do {
            self.cache.user = try await state.http.fetchSelf().get()
            self.cache.accountData = UserSettingsAccountData(
                email: try await state.http.fetchAccount().get().email,
                mfaStatus: try await state.http.fetchMFAStatus().get()
            )
            
            let settingsValues = try await state.http.fetchSettings(keys: ["notifications"]).get()
            let notificationValue = try settingsValues["notifications"].unwrapped().b.replacingOccurrences(of: #"\""#, with: #"""#)
            self.cache.notificationSettings = try JSONDecoder().decode(UserSettingsNotificationsData.self, from: try notificationValue.data(using: .utf8).unwrapped())
            
            self.cacheState = .cached
            writeCacheToFile()
        } catch {
            self.cacheState = .failed
            switch error as? RevoltError {
                case .Alamofire(let afErr):
                    if afErr.responseCode == 401 {
                        await state.setSignedOutState()
                    } else {
                        SentrySDK.capture(error: error)
                    }
                case .HTTPError(let _, let status):
                    if status == 401 {
                        await state.setSignedOutState()
                    } else {
                        SentrySDK.capture(error: error)
                    }
                default:
                    logger.error("An error occurred while fetching user settings: \(error.localizedDescription)")
                    SentrySDK.capture(error: error)
            }
        }
    }
    
    func writeCacheToFile() {
        DispatchQueue.main.async(qos: .utility) {
            if let caches = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let revoltDir = caches.appendingPathComponent(Bundle.main.bundleIdentifier!, conformingTo: .directory)
                do {
                    try FileManager.default.createDirectory(at: revoltDir, withIntermediateDirectories: false)
                } catch {} //ignore error if it already exists
                
                do {
                    let encoded = try JSONEncoder().encode(self.cache)
                    let filePath = UserSettingsData.cacheFile!
                    logger.debug("will write cache to: \(filePath.absoluteString)")
                    try encoded.write(to: filePath)
                } catch {
                    logger.error("Failed to serialize the cache: \(error.localizedDescription)")
                }
            } else {
                // caches not accessible?
                logger.warning("Caches are not accessible. Skipping cache write")
            }
        }
    }
    
    func writeStoreToFile() {
        DispatchQueue.main.async(qos: .utility) {
            if let caches = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let revoltDir = caches.appendingPathComponent(Bundle.main.bundleIdentifier!, conformingTo: .directory)
                do {
                    try FileManager.default.createDirectory(at: revoltDir, withIntermediateDirectories: false)
                } catch {} //ignore error if it already exists
            }
            do {
                let encoded = try JSONEncoder().encode(self.store)
                let filePath = UserSettingsData.storeFile!
                logger.debug("will write settings store to: \(filePath.absoluteString)")
                try encoded.write(to: filePath)
            } catch {
                logger.error("Failed to serialize the settings store: \(error.localizedDescription)")
            }
        }
    }
    
    func destroyCache() {
        DispatchQueue.main.async(qos: .utility, execute: deleteCacheFile)
        self.cache.clear()
        logger.debug("Queued cache file deletion, evicted from memory")
    }
    
    private func deleteCacheFile() {
        let file = UserSettingsData.cacheFile!
        try? FileManager.default.removeItem(at: file)
    }
    
    /// Called when logging out of the app
    func isLoggingOut() {
        destroyCache()
        let file = UserSettingsData.storeFile!
        try? FileManager.default.removeItem(at: file)
        self.store = .init()
        self.store.updateDecodeWithCallback(keyWasSet: storeKeyWasSet)
    }
}
