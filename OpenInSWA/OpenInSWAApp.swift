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
                    Button("Source code & Updates") { openURL(URL(string: "https://github.com/YuhApps/OpenInSWA")!) }
                } message: {
                    Text("Version 1.0.2 (2024.04.10)")
                }
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Open in SWA") { showAboutAlert = true }
                Button("Source code & Updates") { openURL(URL(string: "https://github.com/YuhApps/OpenInSWA")!) }
            }
        }
    }
}
