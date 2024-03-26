//
//  OpenInSWAApp.swift
//  OpenInSWA
//
//  Created by YUH APPS on 26/3/24.
//

import SwiftUI

@main
struct OpenInSWAApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openURL) var openURL
    @State private var showAboutAlert = false
    
    var body: some Scene {
        Window("Open in Safari Web App", id: "main") {
            ContentView()
                .alert("Open in SWA", isPresented: $showAboutAlert) {
                    Button("OK & Close") { showAboutAlert = false }
                    Button("YUH APPS website") { openURL(URL(string: "https://yuhapps.dev")!) }
                } message: {
                    Text("Version 1.0.0 (2024.03.26)")
                }
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Open in SWA") { showAboutAlert = true }
            }
        }
    }
}
