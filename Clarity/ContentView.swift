//
//  ContentView.swift
//  Clarity
//
//  Created by Dan Griffin on 20/01/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)

            Text("Clarity")
                .font(.title)
                .fontWeight(.semibold)

            Text("Reflection begins here.")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
