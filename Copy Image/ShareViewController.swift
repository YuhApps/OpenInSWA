//
//  ShareViewController.swift
//  Copy Image
//
//  Created by YUH APPS on 1/4/24.
//

import Cocoa
import UniformTypeIdentifiers

class ShareViewController: NSViewController {

    override var nibName: NSNib.Name? {
        return NSNib.Name("ShareViewController")
    }

    override func loadView() {
        super.loadView()
    
        // Insert code here to customize the view
        let item = self.extensionContext!.inputItems[0] as! NSExtensionItem
        for attachment in item.attachments! {
            if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                print("ABC")
                attachment.loadItem(forTypeIdentifier: UTType.image.identifier) { image, error in
                    if let image = image as? NSImage {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setData(image.tiffRepresentation, forType: .tiff)
                    } else {
                        print(error ?? "ERROR")
                    }
                }
            } else {
                print("NO IMG ATTCH")
            }
        }
        self.extensionContext!.completeRequest(returningItems: [NSExtensionItem()], completionHandler: nil)
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
