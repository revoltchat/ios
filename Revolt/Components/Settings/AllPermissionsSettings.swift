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
    var filter: Permissions = .all
     
    var body: some View {
        ForEach(Array(filter.makeIterator()), id: \.self) { perm in
            switch permissions {
                case .role(let binding):
                    PermissionSetting(title: perm.name, description: perm.description, value: perm, permissions: binding)
                    
                case .defaultRole(let binding):
                    Toggle(
                        isOn: Binding {
                            binding.wrappedValue.contains(perm)
                        } set: { b in
                            if b {
                                binding.wrappedValue.insert(perm)
                            } else {
                                binding.wrappedValue.remove(perm)
                            }
                        }
                    ) {
                        VStack(alignment: .leading) {
                            Text(perm.name)
                            Text(perm.description)
                                .font(.caption)
                        }
                    }
            }
        }
    }
}
