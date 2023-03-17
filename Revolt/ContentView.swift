//
//  ContentView.swift
//  Revolt
//
//  Created by Paul on 17/03/2023.
//

import SwiftUI

struct ContentView: View {
    @State private var text = ""

    var body: some View {
        VStack {
            TextField(
                "Enter your name",
                text: $text
            ).padding()
            Text(text)
                .padding()
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
