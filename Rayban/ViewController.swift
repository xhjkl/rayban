//
//  ViewController.swift
//  Rayban
//
import Cocoa

class ViewController: NSViewController {
    lazy var openPanel: NSOpenPanel = {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        return panel
    }()
    lazy var detailsCallout: NSPopover = {
        let callout = NSPopover()
        callout.behavior = .Transient
        callout.contentViewController = self.detailsViewController
        return callout
    }()
    lazy var detailsViewController: NSViewController = (
        self.storyboard!.instantiateControllerWithIdentifier(
            "DetailsViewController")
    ) as! NSViewController
    @IBOutlet weak var currentShader: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        let observedSource = ObservedSource.sharedInstance()
        observedSource.addObserver({_ in self.currentShader.stringValue = observedSource.path})

        let result = self.openPanel.runModal()
        if result != NSFileHandlingPanelOKButton {
            NSApp.terminate(self);
        }

        let path = openPanel.URLs.first!.path!
        observedSource.path = path
    }

    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    @IBAction func moreHasBeenClicked(sender: NSButton) {
        self.detailsCallout.showRelativeToRect(
            sender.frame, ofView: sender.superview!, preferredEdge: .MinX)
    }

    @IBAction func currentShaderHasBeenClicked(sender: AnyObject) {
        self.openPanel.beginWithCompletionHandler({ (status) in
            if status != NSFileHandlingPanelOKButton {
                return
            }

            let path = self.openPanel.URLs.first!.path!
            ObservedSource.sharedInstance().path = path
        })
    }

    @IBAction func quitHasBeenClicked(sender: AnyObject) {
        NSApp.terminate(sender);
    }
}
