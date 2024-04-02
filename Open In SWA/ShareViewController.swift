//
//  ShareViewController.swift
//  QuickOpen
//
//  Created by YUH APPS on 1/4/24.
//

import Cocoa
import UniformTypeIdentifiers

class ShareViewController: NSViewController {

    override var nibName: NSNib.Name? {
//        return NSNib.Name("ShareViewController")
        return nil
    }

    override func loadView() {
        super.loadView()
    
        // Insert code here to customize the view
        let item = self.extensionContext!.inputItems[0] as! NSExtensionItem
        if let attachment = item.attachments?.first as? NSItemProvider {
            if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                attachment.loadObject(ofClass: URL.self) { url, error in
                    let bundle = Bundle.main
                    let containerAppBundle = bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
                    NSWorkspace.shared.open([url!], withApplicationAt: containerAppBundle, configuration: NSWorkspace.OpenConfiguration()) { _,_ in
                        let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
                        self.extensionContext!.cancelRequest(withError: cancelError)
                    }
                }
            }
        } else {
            NSLog("No Attachments")
        }
    }

    /*
    @IBAction func send(_ sender: AnyObject?) {
        let outputItem = NSExtensionItem()
        // Complete implementation by setting the appropriate value on the output item
    
        let outputItems = [outputItem]
        self.extensionContext!.completeRequest(returningItems: outputItems, completionHandler: nil)
     }

    @IBAction func cancel(_ sender: AnyObject?) {
        let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
        self.extensionContext!.cancelRequest(withError: cancelError)
    }
     */

}
