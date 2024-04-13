//
//  SettingsView.swift
//  Open in SWA
//
//  Created by YUH APPS on 10/4/24.
//

import SwiftUI

// Unused for now
struct SettingsView : View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    
    @AppStorage("show-swa-in-dock-menu") var showSWAInDockMenu = false
    @AppStorage("show-clear-clipboard-in-dock-menu") var showClearClipboardInDockMenu = false
    
    var body: some View {
        NavigationStack {
            Form {
                Toggle("Show SWA in Dock menu", isOn: $showSWAInDockMenu)
                Toggle("Show Clear Clipboard in Dock menu", isOn: $showClearClipboardInDockMenu)
            }
            .formStyle(.grouped)
            .navigationTitle("\(Image(systemName: "gear"))   Settings")
        }
        .frame(minWidth: 200, minHeight: 160)
    }
}
