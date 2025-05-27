//
//  VoiceChannelView.swift
//  Revolt
//
//  Created by Angelo on 29/03/2024.
//

import Foundation
import SwiftUI
import LiveKit
import Types
import ActivityKit
import AVKit
import LiveKitComponents

private func downloadImage(from url: URL) async throws -> URL? {
    guard var destination = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: "group.chat.revolt.app")
    else { return nil }
    
    destination = destination.appendingPathComponent(url.lastPathComponent)
    
    guard !FileManager.default.fileExists(atPath: destination.path()) else {
        return destination
    }
    
    let (source, _) = try await URLSession.shared.download(from: url)
    try FileManager.default.moveItem(at: source, to: destination)
    return destination
}


struct TokenResponse: Decodable {
    var token: String
}

struct VoiceChannelView: View {
    @EnvironmentObject var viewState: ViewState
    
    var channel: Channel
    var server: Server?
    
    var toggleSidebar: () -> ()
    
    @Binding var disableScroll: Bool
    @Binding var disableSidebar: Bool

    @State var unmuted: Bool = false
    @State var defeaned: Bool = false
    @State var screenSharing: Bool = false
    @State var inCall: Bool = false
    @State var updater: Bool = false
    
    @MainActor
    func connect() async {
        let node = viewState.apiInfo!.features.livekit.nodes.first!
        
        let token = try! await viewState.http.joinVoiceChannel(channel: channel.id, node: node.name).get()
        let dele = VoiceChannelDelegate(updater: $updater)
        let room = Room(delegate: dele, connectOptions: ConnectOptions(autoSubscribe: false))
        
        try! await room.connect(url: node.public_url, token: token.token)
        
        viewState.currentVoiceChannel = channel.id
        viewState.currentVoice = room
        
//        let pfp = URL(string: viewState.currentUser!.avatar != nil ? viewState.formatUrl(with: viewState.currentUser!.avatar!) : "\(viewState.http.baseURL)/users/\(viewState.currentUser!.id)/default_avatar")!;
        
        //        activity = try! Activity.request(
        //            attributes: VoiceWidgetAttributes(
        //                us: viewState.currentUser!,
        //                pfp: pfp,
        //                channel: channel,
        //                channelName: channel.getName(viewState)
        //            ),
        //            content: .init(state: VoiceWidgetAttributes.ContentState(currentlySpeaking: [], weSpeaking: false), staleDate: nil)
        //        )
    }
    
    @MainActor
    func disconnect() async {
        if let room = viewState.currentVoice {
            viewState.currentVoice = nil
            viewState.currentVoiceChannel = nil

            await room.disconnect()
        }
    }
    
    func partipants(room: Room) -> [(Participant, UserMaybeMember)] {
        return room.allParticipants.values
            .compactMap({ participant in
                if let identity = participant.identity?.stringValue {
                    if let user = viewState.users[identity] {
                        return (participant, user)
                    } else if let metadata = participant.metadata?.data(using: .utf8), let user = try? JSONDecoder().decode(User.self, from: metadata) {
                        viewState.users[user.id] = user
                        
                        return (participant, user)
                    } else {
                        return nil
                    }
                }
                
                return nil
            })
            .map({ (p, user) in
                let member = server.flatMap { server in
                    if let member = viewState.members[server.id]?[user.id] {
                        return member as Member?
                    } else {
                        Task {
                            if let member = try? await viewState.http.fetchMember(server: server.id, member: user.id).get() {
                                viewState.members[server.id]?[user.id] = member
                            }
                        }
                        
                        return nil
                    }
                }
                
                return (p, UserMaybeMember(user: user, member: member))
            })
            .sorted(by: { p1, p2 in
                if p1.0 is LocalParticipant { return true }
                if p2.0 is LocalParticipant { return false }
                return (p1.0.joinedAt ?? Date()) < (p2.0.joinedAt ?? Date())
            })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            PageToolbar(toggleSidebar: toggleSidebar) {
                NavigationLink(value: NavigationDestination.channel_info(channel.id)) {
                    ChannelIcon(channel: channel)
                    Image(systemName: "chevron.right")
                        .frame(height: 4)
                }
            }
            
            VStack {
                ScrollView {
                    if let room = viewState.currentVoice {
                        RoomScope(room: room) {
                            ForEach(partipants(room: room), id: \.1.id) { (participant, user) in
                                let title = user.member?.nickname ?? user.user.display_name ?? user.user.username
                                
                                ForEach(participant.trackPublications.values.filter({ $0.kind == .video })) { track in
                                    VoiceChannelBox(title: title) {
                                        let _ = print(track.source, track.kind, track.isSubscribed)
                                        if track is LocalTrackPublication || track.isSubscribed {
                                            SwiftUIVideoView(track.track as! VideoTrack, layoutMode: .fit)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        } else if let remoteTrack = track as? RemoteTrackPublication {
                                            ZStack {
                                                viewState.theme.background3
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                                
                                                Button {
                                                    Task {
                                                        try! await remoteTrack.set(subscribed: true)
                                                    }
                                                } label: {
                                                    Text("Watch")
                                                        .padding(12)
                                                        .background(Capsule().fill(viewState.theme.background2))
                                                }
                                            }
                                        }
                                    } overlay: {
                                        if let remoteTrack = track as? RemoteTrackPublication, remoteTrack.isSubscribed {
                                            Button {
                                                Task {
                                                    try! await remoteTrack.set(subscribed: false)
                                                }
                                            } label: {
                                                Text("Disconnect")
                                                    .padding(8)
                                                    .background(RoundedRectangle(cornerRadius: 8).fill(viewState.theme.error))
                                                    .transition(.opacity)
                                            }
                                            
                                        }
                                    }
                                }
                                
                                VoiceChannelBox(title: title) {
                                    Avatar(user: user.user, member: user.member, width: 48, height: 48)
                                }
                                .addBorder(participant.isSpeaking ? Color.green : Color.clear, width: 1, cornerRadius: 8)
                            }
                        }
                    } else {
                        HStack(alignment: .center) {
                            VStack(alignment: .center) {
                                Text("Not Connected")
                                    .font(.title)
                                Text("Click the join button to connect")
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .contentMargins(.top, 16, for: .scrollContent)
                
                //Spacer()
                
                HStack(spacing: 12) {
                    Group {
                        Button {
                            Task {
                                if inCall, await AVAudioApplication.requestRecordPermission() {
                                    unmuted.toggle()
                                }
                            }
                        } label: {
                            Image(systemName: unmuted ? "mic.fill" : "mic.slash.fill")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        
                        Button { if inCall { screenSharing.toggle() } } label: {
                            Image(systemName: "desktopcomputer")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        
                        Button { inCall.toggle() } label: {
                            Text(inCall ? "Leave Call" : "Join Call")
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Button {
                            withAnimation {
                                viewState.currentChannel = .force_textchannel(channel.id)
                            }
                        } label: {
                            Image(systemName: "bubble.fill")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        
                        Button { if inCall { defeaned.toggle() } } label: {
                            Image(systemName: defeaned ? "speaker.slash.fill" : "speaker.wave.3.fill")
                                .frame(width: 16, height: 16)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            
                        }
                    }
                    .buttonBorderShape(.capsule)
                    .background(viewState.theme.accent)
                    .clipShape(.capsule)
                }
            }
            .padding([.horizontal, .bottom], 16)
        }
        .background(viewState.theme.background)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: inCall, { _, inCall in
            if inCall && viewState.currentVoiceChannel == channel.id {
                return
            }
            
            if inCall {
                Task {
                    await connect()
                }
            } else {
                Task {
                    await disconnect()
                }
            }
        })
        .onChange(of: unmuted, { @MainActor _, unmuted in
            if let room = viewState.currentVoice {
                Task {
                    if unmuted {
                        try! await room.localParticipant.setMicrophone(enabled: true)
                    } else if let micTrack = room.localParticipant.localAudioTracks.first {
                        try! await room.localParticipant.unpublish(publication: micTrack)
                    }
                }
            }
        })
        .onChange(of: screenSharing, { @MainActor _, screenSharing in
            if let room = viewState.currentVoice {
                Task {
                    if screenSharing, await AVAudioApplication.requestRecordPermission() {
                        try! await room.localParticipant.set(source: .screenShareVideo, enabled: screenSharing, captureOptions: ScreenShareCaptureOptions(useBroadcastExtension: false, includeCurrentApplication: true))
                    } else if let micTrack = room.localParticipant.localVideoTracks.first {
                        try! await room.localParticipant.unpublish(publication: micTrack)
                    }

                }
            }
        })
        .onChange(of: updater, { _, _ in })
        .task {
            // resync state when view is reopened
            if viewState.currentVoiceChannel == channel.id {
                inCall = true
            }
        }
    }
}

class VoiceChannelDelegate: RoomDelegate {
    @Binding var updater: Bool
    
    init(updater: Binding<Bool>) {
        self._updater = updater
    }
    func roomDidConnect(_ room: Room) {
        print(room)
    }
    
    func roomDidReconnect(_ room: Room) {
        print("reconnected")
    }
    
    func roomIsReconnecting(_ room: Room) {
        print("reconnecting")
    }
    
    func room(_ room: Room, didDisconnectWithError error: LiveKitError?) {
        print(error)
    }
    
    func room(_ room: Room, trackPublication: TrackPublication, didUpdateE2EEState state: E2EEState) {
        print("track publication \(trackPublication.kind), \(trackPublication.source)")
        print(trackPublication.track)
        
        self.updater.toggle()
    }
    
    func room(_ room: Room, participantDidConnect participant: RemoteParticipant) {
        self.updater.toggle()
    }
    
    func room(_ room: Room, participantDidDisconnect participant: RemoteParticipant) {
        self.updater.toggle()
    }
    
    func room(_ room: Room, participant: LocalParticipant, didPublishTrack publication: LocalTrackPublication) {
        print("local \(publication.kind), \(publication.source)")
        print(publication.track)
        
        self.updater.toggle()
    }
    
    func room(_ room: Room, participant: RemoteParticipant, didPublishTrack publication: RemoteTrackPublication) {
        print("remote \(publication.kind), \(publication.source)")
        print(publication.track)
        
        if publication.kind == .audio {
            Task { try! await publication.set(subscribed: true) }
        }
        
        self.updater.toggle()
    }
}

#Preview {
    let state = ViewState.preview()
    
    VoiceChannelView(
        channel: state.channels["1"]!,
        toggleSidebar: {},
        disableScroll: .constant(false),
        disableSidebar: .constant(false)
    )
    .applyPreviewModifiers(withState: state)
}
