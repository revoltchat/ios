//
//  VoiceWidgetLiveActivity.swift
//  VoiceWidget
//
//  Created by Angelo on 19/05/2024.
//

import ActivityKit
import WidgetKit
import SwiftUI
import Kingfisher
import Types

struct VoiceWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: VoiceWidgetAttributes.self) { ctx in
            VoiceWidgetView(context: ctx)
                .padding()
        } dynamicIsland: { ctx in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    VoiceWidgetView(context: ctx)
                }
            } compactLeading: {
                HStack {
                    ForEach(ctx.state.currentlySpeaking, id: \.self) { url in
//                        try! getImage(fromUrl: url)
                        //Image("logo")
                        Circle()
                            .fill(.red)
//                            .resizable()
//                            .clipShape(Circle())
                            //.overlay(Circle().stroke(Color.green, lineWidth: 2))
                    }
                }
            } compactTrailing: {
//                try! getImage(fromUrl: ctx.attributes.pfp)
                Image(systemName: "pencil.tip.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.red)
//                Circle()
//                    .fill(.red)
//                    .clipShape(Circle())
                    //.overlay(Circle().stroke(ctx.state.weSpeaking ? Color.green : Color.clear, lineWidth: 2))
            } minimal: {
//                try! getImage(fromUrl: ctx.attributes.pfp)
//                Image("logo")
                Circle()
                    .fill(.red)
//                    .resizable()
//                    .clipShape(Circle())
                    //.overlay(Circle().stroke(ctx.state.weSpeaking ? Color.green : Color.clear, lineWidth: 2))
            }
            .widgetURL(URL(string: "revoltchat://channels?channel=\(ctx.attributes.channel.id)"))
        }
    }
}

struct VoiceWidgetView: View {
    var context: ActivityViewContext<VoiceWidgetAttributes>
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(verbatim: context.attributes.channelName)
            }
            HStack {
                Button {
                    
                } label: {
                    Text("Mute")
                }
                
                Button {
                    
                } label: {
                    Text("Deafean")
                }
                
                Button("Leave", role: .destructive) {
                    
                }
            }
        }
        //.padding()
    }
}


//#Preview("Notification", as: .dynamicIsland(.minimal), using: VoiceWidgetAttributes.preview) {
//   VoiceWidgetLiveActivity()
//} contentStates: {
//    VoiceWidgetAttributes.ContentState(currentlySpeaking: [], weSpeaking: false)
//}
