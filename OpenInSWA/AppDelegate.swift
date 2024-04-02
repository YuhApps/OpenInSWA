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
    
    func application(_ application: NSApplication, open urls: [URL]) {
        
        for window in application.windows {
            window.close()
        }
        
        let userApplicationsDirectory = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Applications")
        guard let applications = try? FileManager.default.contentsOfDirectory(at: userApplicationsDirectory, includingPropertiesForKeys: [.isApplicationKey]) else {
            return
        }
        
        for url in urls {
            if url.scheme != "https" {
                continue
            }
            let text = sanitizeURL(url.absoluteString)
            for application in applications {
                if let bundle = Bundle(url: application), let manifest = bundle.infoDictionary?["Manifest"] as? Dictionary<String,Any> {
                    let appStartUrlString = manifest["start_url"] as! String
                    let appStartUrlHost = URL(string: appStartUrlString)!.host()!
                    let textUrl = URL(string: text)!
                    let textUrlHost = textUrl.host()!
                    if appStartUrlHost == textUrlHost || ("www." + appStartUrlHost) == textUrlHost || appStartUrlHost == ("www." + textUrlHost) {
                        let configuration = NSWorkspace.OpenConfiguration()
                        configuration.arguments = [text]
                        NSWorkspace.shared.open([textUrl], withApplicationAt: application, configuration: configuration)
                        return
                    }
                }
            }
        }

        let alert = NSAlert()
        alert.messageText = "No SWA can handle the given URL"
        alert.informativeText = sanitizeURL(urls.first!.absoluteString)
        alert.addButton(withTitle: "Close")
        alert.addButton(withTitle: "Open with Safari")
        if alert.runModal() == .alertSecondButtonReturn {
            for url in urls {
                let text = sanitizeURL(url.absoluteString)
                NSWorkspace.shared.open(URL(string:"x-safari-" + text)!)
            }
        }
    }
    
    func removeUnncessaryMenuItems() {
        if let menu = NSApplication.shared.mainMenu {
            menu.items.removeAll { ["File", "View"].contains($0.title) }
        }
    }
    
    // Santize the given URL to get the final URL after redirection
    func sanitizeURL(_ url: String) -> String {
        if url.contains("https%3A%2F%2F") {
            let startIndex = url.range(of: "https%3A%2F%2F")!.lowerBound
            var str = String(url[startIndex...]).removingPercentEncoding!
            if str.contains("&") && !str.contains("?") {
                let endIndex = str.index(before: str.firstIndex(of: "&")!)
                str = String(str[...endIndex])
            }
            return str
        }
        return url
    }
    
}
