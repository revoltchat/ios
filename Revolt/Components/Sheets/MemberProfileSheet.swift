//
//  MemberProfileSheet.swift
//  Revolt
//
//  Created by Angelo on 27/03/2025.
//

import Foundation
import SwiftUI
import Types
import PhotosUI

struct MemberProfileSheet: View {
    @EnvironmentObject var viewState: ViewState
    
    var server: Server
    
    @State var sheetHeight: CGFloat = .zero
    
    @State var existingMember: Member
    @State var member: Member
        
    @State var error: String? = nil
    
    @State var showAvatarPhotoPicker: Bool = false
    @State var avatarPhoto: PhotosPickerItem? = nil
    
    static func fromViewState(_ viewState: ViewState, server: Server) -> Self {
        let member = viewState.members[server.id]![viewState.currentUser!.id]!
        
        return .init(server: server, existingMember: member, member: member)
    }
    
    func updateValues() async {
        do {
            var payload = EditMemberPayload()
            
            if existingMember.nickname == nil, member.nickname != nil {
                payload.nickname = member.nickname
            } else if member.nickname == nil, existingMember.nickname != nil {
                payload.remove = [.nickname]
            } else {
                return
            }
            
            member = try await viewState.http.editMember(server: server.id, user: viewState.currentUser!.id, payload: payload).get()
            existingMember = member
        } catch let e {
            error = e.localizedDescription
        }
    }
    
    var body: some View {
        let user = viewState.currentUser!
        
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Change identity on \(server.name)")
                    .lineLimit(1)
                    .font(.title2)
                    .frame(alignment: .leading)
            }
            
            HStack(spacing: 16) {
                TextField(user.display_name ?? user.username, text: $member.nickname.bindEmptyToNil())
                    .padding(16)
                    .background(viewState.theme.background2)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                //                    .onChange(of: nickname) { oldValue, newValue in
                //                        member.nickname = newValue
                //                        previewViewModel?.member?.nickname = newValue
                //                        previewViewModel = previewViewModel
                //                    }
                
                Button {
                    Task { await updateValues() }
                } label: {
                    Image(systemName: "checkmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(viewState.theme.foreground2)
                }
                
                Button {
                    member.nickname = nil
                    
                    Task { await updateValues() }
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(viewState.theme.foreground2)
                }
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .center) {
                    Button {
                        showAvatarPhotoPicker = true
                    } label: {
                        if member.avatar != nil {
                            Avatar(user: user, member: member, width: 64, height: 64)
                        } else {
                            ZStack {
                                Avatar(user: user, width: 64, height: 64)
                                
                                Circle()
                                    .fill(.black.opacity(0.5))
                                    .blendMode(.darken)
                                    .frame(width: 64, height: 64)
                            }
                        }
                    }
                    .photosPicker(isPresented: $showAvatarPhotoPicker, selection: $avatarPhoto)
                    .onChange(of: avatarPhoto) { (_, new) in
                        Task {
                            do {
                                if let photo = new {
                                    if let data = try? await photo.loadTransferable(type: Data.self) {
                                        let file = try await viewState.http.uploadFile(data: data, name: "icon.\(photo.supportedContentTypes[0].preferredFilenameExtension!)", category: .avatar).get()
                                        
                                        member = try await viewState.http.editMember(server: server.id, user: user.id, payload: EditMemberPayload(avatar: file.id)).get()
                                    }
                                }
                            } catch let e {
                                error = e.localizedDescription
                            }
                        }
                    }
                    
                    Button {
                        Task {
                            do {
                                member = try await viewState.http.editMember(server: server.id, user: user.id, payload: EditMemberPayload(remove: [.avatar])).get()
                            } catch let e {
                                error = e.localizedDescription
                            }
                        }
                    } label: {
                        Text("Remove")
                            .font(.caption)
                            .foregroundStyle(viewState.theme.foreground2)
                    }
                }
                
                MessageView(viewModel: MessageContentsViewModel(
                    viewState: viewState,
                    message: .constant(Message(id: "00000000000000000000000000", content: "Hello everyone!", author: viewState.currentUser!.id, channel: "00000000000000000000000000")),
                    author: .constant(viewState.currentUser!),
                    member: Binding($member),
                    server: .constant(server),
                    channel: .constant(Channel.text_channel(TextChannel(id: "00000000000000000000000000", server: server.id, name: "Fake Channel"))),
                    replies: .constant([]),
                    channelScrollPosition: .empty,
                    editing: .constant(nil)
                ), isStatic: true)
            }
        }
        .padding(16)
        .presentationBackground(viewState.theme.background)
        .overlay {
            GeometryReader { geometry in
                Color.clear.preference(key: InnerHeightPreferenceKey.self, value: geometry.size.height)
            }
        }
        .onPreferenceChange(InnerHeightPreferenceKey.self) { newHeight in
            sheetHeight = newHeight
        }
        .presentationDetents([.height(sheetHeight)])

    }
}
