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
    @State private var showAnUpdateAvailable = false
    @State private var showNoUpdateAvailable = false
    @State private var showSettingsSheet = false
    
    let build_date = "(2024.04.16)"
    
    var body: some Scene {
        Window("Open in Safari Web App", id: "main") {
            ContentView()
                .alert("Open in SWA", isPresented: $showAboutAlert) {
                    Button("OK & Close") { showAboutAlert = false }
                    Button("YUH APPS website") { openURL(URL(string: "https://yuhapps.dev")!) }
                    Button("Source code") {
                        let textUrl = URL(string: "https://github.com/YuhApps/OpenInSWA")!
                        let userApplicationsDirectory = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Applications")
                        guard let applications = try? FileManager.default.contentsOfDirectory(at: userApplicationsDirectory, includingPropertiesForKeys: [.isApplicationKey]) else {
                            return
                        }
                        for application in applications {
                            if let bundle = Bundle(url: application), let manifest = bundle.infoDictionary?["Manifest"] as? Dictionary<String,Any> {
                                let appStartUrlString = manifest["start_url"] as! String
                                let appStartUrlHost = URL(string: appStartUrlString)!.host()!
                                let textUrlHost = textUrl.host()!
                                if appStartUrlHost == textUrlHost || ("www." + appStartUrlHost) == textUrlHost || appStartUrlHost == ("www." + textUrlHost) {
                                    let configuration = NSWorkspace.OpenConfiguration()
                                    configuration.arguments = [textUrl.absoluteString]
                                    configuration.activates = true
                                    NSWorkspace.shared.open([textUrl], withApplicationAt: application, configuration: configuration)
                                    return
                                }
                            }
                        }
                        openURL(textUrl)
                    }
                } message: {
                    Text("Version \(Bundle.main.infoDictionary!["CFBundleShortVersionString"]!) \(build_date)")
                }
                .alert("There's a new update", isPresented: $showAnUpdateAvailable) {
                    Button("Download now") { openURL(URL(string: "https://github.com/YuhApps/OpenInSWA/releases")!) }
                }
                .alert("You have the latest version", isPresented: $showNoUpdateAvailable) {
                    Button("Close") { showNoUpdateAvailable = false }
                }
                /* Unused for now
                .sheet(isPresented: $showSettingsSheet) {
                    SettingsView()
                }
                 */
                .environment(\.appDelegate, appDelegate)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Open in SWA") { showAboutAlert = true }
                Button("Check for update") { Task { await checkForUpdate() } }
            }
        }
    }
    
    func checkForUpdate() async {
        let url = URL(string: "https://api.github.com/repos/YuhApps/OpenInSWA/releases/latest")!
        let (data, _) = try! await URLSession.shared.data(from: url)
        let response = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
        let newVersion = response["name"]! as! String
        let oldVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"]! as! String
        let result = isUpdateAvailable(oldVersion: oldVersion, newVersion: newVersion)
        showAnUpdateAvailable = result
        showNoUpdateAvailable = !result
    }
    
    func isUpdateAvailable(oldVersion: String, newVersion: String) -> Bool {
        let ov = oldVersion.split(separator: ".")
        let nv = newVersion.split(separator: ".")
        for i in 0...2 {
            let o = Int(ov[i])!
            let n = Int(nv[i])!
            if n > o {
                return true
            }
        }
        return false
    }
}

private struct AppDelegateKey: EnvironmentKey {
    static let defaultValue: AppDelegate = AppDelegate()
}

extension EnvironmentValues {
    var appDelegate: AppDelegate {
        get { self[AppDelegateKey.self] }
        set { self[AppDelegateKey.self] = newValue }
    }
}
