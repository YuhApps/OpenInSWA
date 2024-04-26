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
    
    func applicationDidBecomeActive(_ notification: Notification) {
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
        
        var unhandledURLs = [URL]()
        
        for url in urls {
            if url.scheme == "x-safari-private-https" {
                let absoluteString = url.absoluteString
                let startIndex = absoluteString.range(of: "x-safari-private-")!.upperBound
                let string = String(absoluteString[startIndex...])
                openInSafariPrivate([URL(string: string)!])
            } else if url.scheme == "https" {
                let text = sanitizeURL(url.absoluteString)
                var unhandled = true
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
                            unhandled = false
                            break
                        }
                    }
                }
                if unhandled {
                    unhandledURLs.append(url)
                }
            }
        }

        if unhandledURLs.count > 0 {
            for url in unhandledURLs {
                let alert = NSAlert()
                alert.messageText = "No SWA can open the given URL"
                alert.informativeText = sanitizeURL(url.absoluteString)
                alert.addButton(withTitle: "Close")
                alert.addButton(withTitle: "Open with Safari")
                alert.addButton(withTitle: "Open with Safari Private")
                let ret = alert.runModal()
                if ret == .alertSecondButtonReturn {
                    let text = sanitizeURL(url.absoluteString)
                    NSWorkspace.shared.open(URL(string:"x-safari-" + text)!)
                } else if ret == .alertThirdButtonReturn {
                    openInSafariPrivate(urls)
                }
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
        var ret = url
        if url.contains("https%3A%2F%2F") { // For example, https://l.instagram.com/?u=http%3A%2F%2Fmeta.com
            let startIndex = url.range(of: "https%3A%2F%2F")!.lowerBound
            var str = String(url[startIndex...]).removingPercentEncoding!
            if str.contains("&") && !str.contains("?") {
                let endIndex = str.index(before: str.firstIndex(of: "&")!)
                str = String(str[...endIndex])
            }
            ret = str
        } else if url.contains("?url=https://") || url.contains("&url=https://") { // For example https://www.google.com/url?sa=t&source=web&rct=j&url=https://www.youtube.com/%40Apple
            let queries = URL(string: url)!.query()!.split(separator: "&", omittingEmptySubsequences: true)
            let urlQuery = queries.first(where: { String($0).starts(with: "url") })!
            let startIndex = urlQuery.range(of: "https://")!.lowerBound
            let str = String(urlQuery[startIndex...]).removingPercentEncoding!
            ret = str
        }
        // Replace "https://m." with "https://www."
        if ret.starts(with: "https://m.") {
            let startIndex = url.range(of: "https://m.")!.upperBound
            ret = "https://www." + String(ret[startIndex...])
        }
        return ret
    }
    
    @discardableResult
    func openInSafariPrivate(_ urls: [URL]) -> String? {
        let trusted = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
        let privOptions = [trusted: false] as CFDictionary
        let accessEnabled = AXIsProcessTrustedWithOptions(privOptions)
        if accessEnabled {
            // Source https://github.com/sindresorhus/Safari-Private/blob/main/Safari%20Private/Utilities.swift
            var error: NSDictionary?
            let source = #"""
                tell application "Safari" to activate
                
                tell application "System Events" to tell its application process "Safari"
                    set frontmost to true
                    keystroke "n" using {shift down, command down}
                end tell
                
                tell application "Safari"
                    delay 0.2
                    \#(urls.map { #"open location "\#($0.absoluteString)""# }.joined(separator: "\n"))
                end tell
            """#
            let ret = NSAppleScript(source: source)?.executeAndReturnError(&error).stringValue
            print(error ?? ret ?? "Something went wrong")
            return ret
        } else {
            let alert = NSAlert()
            alert.messageText = "Open In SWA requires Accessibility permission"
            alert.informativeText = "Please open System Settings → Privacy & Security → Accessibility and add Open In SWA to the list."
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Close")
            NSApp.activate(ignoringOtherApps: true)
            if alert.runModal() == .alertFirstButtonReturn, let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
                NSApp.terminate(NSApp)
            }
            return ""
        }
    }
    
    func subString(string: String, from: Int, to: Int) -> String {
       let startIndex = string.index(string.startIndex, offsetBy: from)
       let endIndex = string.index(string.startIndex, offsetBy: to)
       return String(string[startIndex..<endIndex])
    }
    
}
