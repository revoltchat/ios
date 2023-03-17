//
//  ContentView.swift
//  Revolt
//
//  Created by Paul on 17/03/2023.
//

import SwiftUI

struct ContentView: View {
    @State private var show = false
    
    var body: some View {
        VStack {
            Image(systemName: "person.3")
                .imageScale(.large)
                .foregroundColor(.red)
            Text("hello chat")
            Button("easter egg") {
                show.toggle();
            }
            
            if show {
                Text("among us")
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
