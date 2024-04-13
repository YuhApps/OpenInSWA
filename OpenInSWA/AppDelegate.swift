//
//  AppDelegate.swift
//  Open in SWA
//
//  Created by YUH APPS on 26/3/24.
//

import Cocoa

@Observable
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

    @objc func clearClipboard(_ sender: NSMenuItem) {
        NSPasteboard.general.clearContents()
    }
    
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let userApplicationsDirectory = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Applications")
        guard let applications = try? FileManager.default.contentsOfDirectory(at: userApplicationsDirectory, includingPropertiesForKeys: [.isApplicationKey]), applications.count > 0 else {
            return nil
        }

        let menu = NSMenu()
        for application in applications.sorted(by: { $0.lastPathComponent.localizedCompare($1.lastPathComponent).rawValue > 0 }) {
            if application.lastPathComponent.starts(with: ".") || application.pathExtension != "app" {
                continue
            }
            let applicationString = application.absoluteString
            let menuItem = NSMenuItem(title: application.deletingPathExtension().lastPathComponent, action: #selector(openApplicationURL), keyEquivalent: "")
            menuItem.representedObject = application
            menuItem.image = NSWorkspace.shared.icon(forFile: subString(string: applicationString, from: "file://".count, to: applicationString.count).removingPercentEncoding!)
            menuItem.image!.size = NSSize(width: 16, height: 16)
            menu.addItem(menuItem)
        }
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Clear Clipboard", action: #selector(clearClipboard), keyEquivalent: ""))
        return menu
    }
    
    @objc func openApplicationURL(_ sender: NSMenuItem) {
        let url = sender.representedObject as! URL
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
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
                        configuration.activates = true
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
        if url.contains("https%3A%2F%2F") { // For example, https://l.instagram.com/?u=http%3A%2F%2Fmeta.com
            let startIndex = url.range(of: "https%3A%2F%2F")!.lowerBound
            var str = String(url[startIndex...]).removingPercentEncoding!
            if str.contains("&") && !str.contains("?") {
                let endIndex = str.index(before: str.firstIndex(of: "&")!)
                str = String(str[...endIndex])
            }
            return str
        } else if url.contains("?url=https://") || url.contains("&url=https://") { // For example https://www.google.com/url?sa=t&source=web&rct=j&url=https://www.youtube.com/%40Apple
            let queries = URL(string: url)!.query()!.split(separator: "&", omittingEmptySubsequences: true)
            let urlQuery = queries.first(where: { String($0).starts(with: "url") })!
            let startIndex = urlQuery.range(of: "https://")!.lowerBound
            let str = String(urlQuery[startIndex...]).removingPercentEncoding!
            return str
        }
        // TODO: Replace "https://m." with "https://www."
        return url
    }
    
    func subString(string: String, from: Int, to: Int) -> String {
       let startIndex = string.index(string.startIndex, offsetBy: from)
       let endIndex = string.index(string.startIndex, offsetBy: to)
       return String(string[startIndex..<endIndex])
    }
    
}
