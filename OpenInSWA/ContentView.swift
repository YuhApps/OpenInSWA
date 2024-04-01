//
//  ContentView.swift
//  OpenInSWA
//
//  Created by YUH APPS on 26/3/24.
//

import SwiftUI

struct InvalidURLError: LocalizedError {
    var errorDescription: String? {
        return "Invalid URL."
    }
    
    var errorMessage: String? {
        return "Message"
    }
}

struct NoSWAError: LocalizedError {
    
    var errorDescription: String? {
        return "No Safari Web Apps can handle the given URL."
    }
    
    var errorMessage: String? {
        return "Message"
    }
}

struct ContentView: View {
    
    private let userApplicationsDirectory = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Applications")
    @Environment(\.scenePhase) var scenePhase
    
    @State private var showFileImporter = false
    @State private var showInvalidURLAlert = false
    @State private var showNoSWAAlert = false
    @State private var text = ""
    
    
    var body: some View {
        VStack(spacing: 20.0) {
            TextField(text: $text) {
                Text("Enter full URL, with https:// prefix")
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .onAppear(perform: pasteCopiedUrlIfNeeded)
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification), perform: clearText)
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeMainNotification), perform: pasteCopiedUrlIfNeeded)
            .onSubmit(openInDefaultSWA)
            HStack {
                Button("Open in Default SWA", action: openInDefaultSWA)
                Spacer()
                Button("Open in another app") { showFileImporter = true }
            }
            .padding(.horizontal, 20)
        }
        .padding(.all, 20)
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.application]) {
            if let textUrl = URL(string: text), let applicationUrl = try? $0.get() {
                let configuration = NSWorkspace.OpenConfiguration()
                configuration.arguments = [text]
                NSWorkspace.shared.open([textUrl], withApplicationAt: applicationUrl, configuration: configuration)
            }
        }
        .alert(isPresented: $showInvalidURLAlert, error: InvalidURLError()) {
            Button("Close") {
                showInvalidURLAlert = false
            }
        }
        .alert(isPresented: $showNoSWAAlert, error: NoSWAError()) {
            Button("Close") {
                showNoSWAAlert = false
            }
        }
    }
    
    func pasteCopiedUrlIfNeeded() {
        let pasteboard = NSPasteboard.general
        if let string = pasteboard.string(forType: .string), string.starts(with: "https://") {
            self.text = sanitizeURL(string)
        }
    }
    
    func pasteCopiedUrlIfNeeded(_ output: NotificationCenter.Publisher.Output) {
        if text.isEmpty == false {
            return
        }
        let pasteboard = NSPasteboard.general
        if let string = pasteboard.string(forType: .string), string.starts(with: "https://") {
            self.text = sanitizeURL(string)
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
    
    func clearText(_ output: NotificationCenter.Publisher.Output) {
        text = ""
    }
    
    func openInDefaultSWA() {
        if text.starts(with: "https://") == false {
            showInvalidURLAlert = true
            return
        }
        
        guard let applications = try? FileManager.default.contentsOfDirectory(at: userApplicationsDirectory, includingPropertiesForKeys: [.isApplicationKey]) else {
            return
        }
        
        let text = sanitizeURL(self.text)
        
        for application in applications {
            if let bundle = Bundle(url: application), let manifest = bundle.infoDictionary?["Manifest"] as? Dictionary<String,Any> {
                let appStartUrlString = manifest["start_url"] as! String
                let appStartUrlHost = URL(string: appStartUrlString)!.host()!
                let textUrl = URL(string: text)!
                if appStartUrlHost == textUrl.host()! {
                    let configuration = NSWorkspace.OpenConfiguration()
                    configuration.arguments = [text]
                    NSWorkspace.shared.open([textUrl], withApplicationAt: application, configuration: configuration)
                    return
                }
            }
        }
        
        showNoSWAAlert = true
    }
}

#Preview {
    ContentView()
}
