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

    @Binding var showSidebar: Bool

    @State var unmuted: Bool = false
    @State var defeaned: Bool = false
    @State var screenSharing: Bool = false
    @State var inCall: Bool = false
    @State var updater: Bool = false

    @State var activity: Activity<VoiceWidgetAttributes>? = nil

    @MainActor
    func connect() async {
        let token = try! await viewState.http.joinVoiceChannel(channel: channel.id).get()
        let dele = VoiceChannelDelegate(updater: $updater)
        let room = Room(delegate: dele)

        try! await room.connect(url: viewState.apiInfo!.features.livekit.url.replacing("http", with: "ws", maxReplacements: 1), token: token.token)

        viewState.currentVoiceChannel = channel.id
        viewState.currentVoice = room

        let pfp = URL(string: viewState.currentUser!.avatar != nil ? viewState.formatUrl(with: viewState.currentUser!.avatar!) : "\(viewState.http.baseURL)/users/\(viewState.currentUser!.id)/default_avatar")!;

        activity = try! Activity.request(
            attributes: VoiceWidgetAttributes(
                us: viewState.currentUser!,
                pfp: pfp,
                channel: channel,
                channelName: channel.getName(viewState)
            ),
            content: .init(state: VoiceWidgetAttributes.ContentState(currentlySpeaking: [], weSpeaking: false), staleDate: nil)
        )
    }

    @MainActor
    func disconnect() async {
        if let room = viewState.currentVoice {
            await room.disconnect()
            viewState.currentVoice = nil
            viewState.currentVoiceChannel = nil
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            PageToolbar(showSidebar: $showSidebar) {
                NavigationLink(value: NavigationDestination.channel_info(channel.id)) {
                    ChannelIcon(channel: channel)
                    Image(systemName: "chevron.right")
                        .frame(height: 4)
                }
            } trailing: {
                EmptyView()
            }

            ScrollView {
                if let room = viewState.currentVoice {
                    VStack(alignment: .leading) {
                        ForEach(Array(room.allParticipants.values), id: \.identity!.stringValue) { participant in
                            let user = viewState.users[participant.identity!.stringValue]!

                            GeometryReader { proxy in
                                VStack(alignment: .leading) {
                                    HStack {
                                        Spacer()
                                        VStack {
                                            Spacer()
                                            Avatar(user: user, width: 48, height: 48)
                                            Spacer()
                                        }
                                        Spacer()
                                    }


                                    Text(user.username)
                                }
                                .frame(width: proxy.size.width - 16, height: ((proxy.size.width - 16) / 9) * 6)
                                .padding(8)
                                .background(viewState.theme.background2)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
//                        ForEach(Array(room.0.allParticipants.values).sorted(by: { a, b in a.id < b.id })) { participant in
//                            let user = viewState.users[participant.identity!.stringValue]!
//
//                            ForEach(participant.videoTracks) { publication in
//                                if let track = publication.track as? VideoTrack {
//                                    GeometryReader { proxy in
//                                        VStack(alignment: .leading) {
//                                            SwiftUIVideoView(track)
//                                                .frame(width: proxy.size.width - 16, height: ((proxy.size.width - 16) / 9) * 6)
//                                            Text(participant.identity?.stringValue ?? "Unknown")
//                                        }
//                                        .padding(8)
//                                        .background(viewState.theme.background2)
//                                        .clipShape(RoundedRectangle(cornerRadius: 8))
//                                    }
//                                }
//                            }
//
//                            if participant.videoTracks.compactMap({ $0.track as? VideoTrack }).count == 0 {
//                                GeometryReader { proxy in
//                                    VStack(alignment: .leading) {
//                                        HStack {
//                                            Spacer()
//                                            VStack {
//                                                Spacer()
//                                                Avatar(user: user, width: 48, height: 48)
//                                                Spacer()
//                                            }
//                                            Spacer()
//                                        }
//
//
//                                        Text(user.username)
//                                    }
//                                    .frame(width: proxy.size.width - 16, height: ((proxy.size.width - 16) / 9) * 6)
//                                    .padding(8)
//                                    .background(viewState.theme.background2)
//                                    .clipShape(RoundedRectangle(cornerRadius: 8))
//                                }

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

            //Spacer()

            HStack(spacing: 12) {
                Group {
                    Button { unmuted.toggle() } label: {
                        Image(systemName: unmuted ? "mic.fill" : "mic.slash.fill")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }

                    Button { screenSharing.toggle() } label: {
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
                        viewState.currentChannel = .force_textchannel(channel.id)
                    } label: {
                        Image(systemName: "bubble.fill")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }

                    Button { defeaned.toggle() } label: {
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
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(viewState.theme.background)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: inCall, { _, inCall in
            print(inCall)
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
                    try! await room.localParticipant.setMicrophone(enabled: unmuted)
                }
            }
        })
        .onChange(of: screenSharing, { @MainActor _, screenSharing in
            if let room = viewState.currentVoice {
                Task {
                    try! await room.localParticipant.setScreenShare(enabled: screenSharing)
                }
            }
        })
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

        self.updater.toggle()
    }
}

#Preview {
    let state = ViewState.preview()

    return VoiceChannelView(channel: state.channels["1"]!, showSidebar: .constant(false))
        .applyPreviewModifiers(withState: state)
}
