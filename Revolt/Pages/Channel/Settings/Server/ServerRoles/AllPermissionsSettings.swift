//
//  AllPermissionsSettings.swift
//  Revolt
//
//  Created by Angelo on 25/09/2024.
//

import Foundation
import SwiftUI
import Types

struct PermissionSetting: View {
    var title: String
    var description: String
    var value: Permissions
    
    @Binding var permissions: Overwrite
    
    var customBinding: Binding<Bool?> {
        Binding {
            if permissions.a.contains(value) {
                return true
            } else if permissions.d.contains(value) {
                return false
            } else {
                return nil
            }
        } set: {
            switch $0 {
                case .some(true):
                    permissions.a.insert(value)
                    permissions.d.remove(value)
                case .some(false):
                    permissions.d.insert(value)
                    permissions.a.remove(value)
                case .none:
                    permissions.a.remove(value)
                    permissions.d.remove(value)
            }
        }
    }
    
    var body: some View {
        PermissionToggle(value: customBinding) {
            VStack(alignment: .leading) {
                Text(title)
                Text(description)
                    .font(.caption)
            }
        }
    }
}


struct AllPermissionSettings: View {
    enum RolePermissions {
        case role(Binding<Overwrite>)
        case defaultRole(Binding<Permissions>)
    }
    
    var permissions: RolePermissions
    
    var body: some View {
        ForEach([
            ("Manage Channels", "Allows members to edit or delete a channel.", Permissions.manageChannel),
            ("Manage Server", "Allows members to change this server's name, description, icon and other related information.", .manageServer),
            ("Manage Permissions", "Allows members to change permissions for channels and roles with a lower ranking.", .managePermissions),
            ("Manage Roles", "Allows members to create, edit and delete roles with a lower rank than theirs, and modify role permissions on channels.", .manageRole),
            ("Manage Customisations", "Allows members to create, edit and delete emojis.", .manageCustomisation),
            ("Kick Members", "Allows members to remove members from this server. Kicked members may rejoin with an invite.", .kickMembers),
            ("Ban Members", "Allows members to permanently remove members from this server.", .banMembers),
            ("Timeout Members", "Allows members to temporarily prevent users from interacting with the server.", .timeoutMembers),
            ("Assign Roles", "Allows members to assign roles below their own rank to other members.", .assignRoles),
            ("Change Nickname", "Allows members to change their nickname on this server.", .changeNicknames),
            ("Manage Nicknames", "Allows members to change the nicknames of other members.", .manageNickname),
            ("Change Avatar", "Allows members to change their avatar on this server.", .changeAvatars),
            ("Remove Avatars", "Allows members to remove the server avatars of other members on this server.", .removeAvatars),
            ("View Channel", "Allows members to view any channels they have this permission on.", .viewChannel),
            ("Send Messages", "Allows members to send messages in text channels.", .sendMessages),
            ("Manage Messages", "Allows members to delete messages sent by other members.", .manageMessages),
            ("Invite Others", "Allows members to invite other users to a channel.", .inviteOthers),
            ("Send Embeds", "Allows members to send embedded content, whether from links or custom text embeds.", .sendEmbeds),
            ("Upload Files", "Allows members to upload files in text channels.", .uploadFiles),
            ("Masquerade", "Allows members to change their name and avatar per-message.", .masquerade),
            ("Use Reactions", "Allows members to react to messages.", .react),
            ("Connect", "Allows members to connect to a voice channel.", .connect)
        ], id: \.0) { perm in
            switch permissions {
                case .role(let binding):
                    PermissionSetting(title: perm.0, description: perm.1, value: perm.2, permissions: binding)
                    
                case .defaultRole(let binding):
                    Toggle(
                        perm.0,
                        isOn: Binding {
                            binding.wrappedValue.contains(perm.2)
                        } set: { b in
                            if b {
                                binding.wrappedValue.insert(perm.2)
                            } else {
                                binding.wrappedValue.remove(perm.2)
                            }
                        }
                    )
            }
        }
    }
}
