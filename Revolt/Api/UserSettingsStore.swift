//
//  UserSettingsStore.swift
//  Revolt
//
//  Created by Angelo on 2024-02-23.
//

import Foundation
import Observation
import OSLog
import Types

let logger = Logger(subsystem: "chat.revolt.app", category: "settingsStore")

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

@Observable
class UserSettingsStore: Codable {
    var user: User?
    var accountData: UserSettingsAccountData?
    
    fileprivate func clear() {
        user = nil
        accountData = nil
    }
}


class UserSettingsData {
    enum SettingsFetchState {
        case fetching, failed, cached
    }
    
    var viewState: ViewState?
    var store: UserSettingsStore
    var dataState: SettingsFetchState
    
    static var cacheFile: URL? {
        if let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let revoltDir = caches.appendingPathComponent("RevoltCaches", conformingTo: .directory)
            let resp = revoltDir.appendingPathComponent("settingsCache", conformingTo: .json)
            return resp
        }
        return nil
    }

    init(viewState: ViewState?, store: UserSettingsStore) {
        self.viewState = viewState
        self.store = store
        self.dataState = .cached
    }
    
    init(viewState: ViewState?) {
        self.viewState = viewState
        self.store = UserSettingsStore()
        self.dataState = .fetching
        
        createFetchTask()
    }
    
    class func maybeRead(viewState: ViewState?) -> UserSettingsData {
        let filePath = UserSettingsData.cacheFile!
        var file = Data()
        do {
            file = try Data(contentsOf: filePath)
        } catch {
            logger.debug("settingsCache file does not exist")
            return UserSettingsData(viewState: viewState)
        }
        do {
            let data = try JSONDecoder().decode(UserSettingsStore.self, from: file)
            return UserSettingsData(viewState: viewState, store: data)
        } catch {
            logger.warning("Failed to parse the existing cache file. Discarding file and rebuilding cache")
            return UserSettingsData(viewState: viewState)
        }
    }
    
    func createFetchTask() {
        Task(priority: .medium, operation: self.fetchFromApi)
    }
    
    @Sendable func fetchFromApi() async {
        while viewState == nil {
            try! await Task.sleep(for: .seconds(1))
        }
        let state = viewState!
        
        do {
            self.store.user = try await state.http.fetchSelf().get()
            self.store.accountData = UserSettingsAccountData(
                email: try await state.http.fetchAccount().get().email,
                mfaStatus: try await state.http.fetchMFAStatus().get()
            )
            
            self.dataState = .cached
            writeCacheToFile()
        } catch {
            self.dataState = .failed
            logger.error("An error occurred while fetching user settings: \(error.localizedDescription)")
        }
    }
    
    private func writeCacheToFile() {
        DispatchQueue.main.async(qos: .utility) {
            if let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
                let revoltDir = caches.appendingPathComponent("RevoltCaches", conformingTo: .directory)
                do {
                    try FileManager.default.createDirectory(at: revoltDir, withIntermediateDirectories: false)
                } catch {} //ignore error if it already exists
                
                do {
                    let encoded = try JSONEncoder().encode(self.store)
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
    
    func destroyCache() {
        DispatchQueue.main.async(qos: .utility, execute: deleteCacheFile)
        self.store.clear()
        logger.debug("Queued cache file deletion, evicted from memory")
    }
    
    private func deleteCacheFile() {
        let file = UserSettingsData.cacheFile!
        try? FileManager.default.removeItem(at: file)
    }
}
