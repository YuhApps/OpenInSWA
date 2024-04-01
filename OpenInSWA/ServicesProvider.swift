//
//  ServicesProvider.swift
//  Open in SWA
//
//  Created by YUH APPS on 28/3/24.
//

import Cocoa

// Not working as of this moment.
class ServicesProvider: NSObject {
    
    @objc func service(_ pasteboard: NSPasteboard, userData: String?, error: UnsafeMutablePointer<NSString>) {
        print("ABCDEFGH")
        guard let str = pasteboard.string(forType: .string) else {
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = "Welcome in the service"
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }
    
        let alert = NSAlert()
        alert.messageText = "Hello \(str)"
        alert.informativeText = "Welcome in the service"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
