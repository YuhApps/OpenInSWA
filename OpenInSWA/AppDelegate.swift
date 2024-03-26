//
//  AppDelegate.swift
//  Open in SWA
//
//  Created by YUH APPS on 26/3/24.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        removeUnncessaryMenuItems()
    }
    
    func applicationWillBecomeActive(_ notification: Notification) {
        removeUnncessaryMenuItems()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
    
    func removeUnncessaryMenuItems() {
        if let menu = NSApplication.shared.mainMenu {
            menu.items.removeAll { ["File", "View"].contains($0.title) }
        }
    }
}
