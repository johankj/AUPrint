//
//  AppDelegate.swift
//  AUPrint
//
//  Created by Johan K. Jensen on 21/06/2015.
//  Copyright © 2015 Johan K. Jensen. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var addPrinterButton: NSButton!
    @IBOutlet weak var progressLabel: NSTextField!
    
    var printers: NSMutableArray = []
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        for tableColumn in tableView.tableColumns {
            let sortDescriptor = NSSortDescriptor(key: tableColumn.identifier, ascending: true, selector: "caseInsensitiveCompare:")
            tableColumn.sortDescriptorPrototype = sortDescriptor
        }
        
        let printersFile = NSBundle.mainBundle().pathForResource("printers", ofType: "json")!
        let printersData = NSData(contentsOfFile: printersFile)!
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(printersData, options: NSJSONReadingOptions.MutableContainers) as! NSArray
            for var data in json {
//                let p = MyPrinter(name: data["name"], location: data["location"], url: data["url"], driver: data["driver"])
                let name = data["name"] as! String
                let location = data["location"] as! String
                let url = data["url"] as! String
                let driver = data["driver"] as! String
                let p = MyPrinter(name: name, location: location, url: url, driver: driver)
                printers.addObject(p)
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Failed loading printer info"
            alert.informativeText = "Couldn’t correctly parse the printer information."
            alert.alertStyle = .CriticalAlertStyle
            alert.beginSheetModalForWindow(self.window, completionHandler: nil)
        }
        tableView.reloadData()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(theApplication: NSApplication) -> Bool {
        return true
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return printers.count
    }

    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let result: NSTableCellView = tableView.makeViewWithIdentifier("textCell", owner: self) as? NSTableCellView else { return nil }
        guard let printer = printers[row] as? MyPrinter else { return nil }
        switch tableColumn!.identifier {
        case "name":
            result.textField?.stringValue = printer.name
        case "location":
            result.textField?.stringValue = printer.location
        case "url":
            result.textField?.stringValue = printer.url
        case "driver":
            result.textField?.stringValue = printer.driver
        default:
            return nil
        }
        return result
    }
    
    func tableView(tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        printers.sortUsingDescriptors(tableView.sortDescriptors)
        tableView.reloadData()
    }
    
    func tableViewSelectionIsChanging(notification: NSNotification) {
        updateOnSelectionChanges()
    }
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        updateOnSelectionChanges()
    }
    
    func updateOnSelectionChanges() {
        if tableView.selectedRowIndexes.count > 1 {
            addPrinterButton.title = "Add Selected Printers"
        } else {
            addPrinterButton.title = "Add Selected Printer"
        }
        progressLabel.stringValue = "Added 0 of \(tableView.selectedRowIndexes.count) printers"
    }
    
    @IBAction func addSelectedPrinters(sender: AnyObject) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let printersToAdd = self.printers.objectsAtIndexes(self.tableView.selectedRowIndexes)
            var i = 0
            for printer in printersToAdd {
                self.addPrinter(printer as! MyPrinter)
                dispatch_async(dispatch_get_main_queue()) {
                    self.progressLabel.stringValue = "Added \(++i) of \(printersToAdd.count) printers"
                }
            }
        }
    }
    
    func addPrinter(printer: MyPrinter) {
        let task = NSTask()
        task.launchPath = "/usr/sbin/lpadmin"
        task.arguments = ["-p", printer.name, "-L", printer.location, "-E", "-v", printer.url, "-P", "/System/Library/Frameworks/ApplicationServices.framework/Frameworks/PrintCore.framework/Resources/Generic.ppd", "-o", "printer-is-shared=false"]
        task.launch()
        task.waitUntilExit()
        if task.terminationStatus != 0 {
            dispatch_async(dispatch_get_main_queue()) {
                let alert = NSAlert()
                alert.messageText = "Failed adding printer"
                alert.informativeText = "While trying to add printer “\(printer.name)” an error occured."
                alert.alertStyle = .CriticalAlertStyle
                alert.beginSheetModalForWindow(self.window, completionHandler: nil)
            }
        }
    }
    
    @IBAction func openPrintPreferences(sender: AnyObject) {
        if #available(OSX 10.10, *) {
            NSWorkspace.sharedWorkspace().openURL(NSURL(string: "x-apple.systempreferences:com.apple.preference.printfax?print")!)
        } else {
            let path = "/System/Library/PreferencePanes/PrintAndFax.prefPane"
            NSWorkspace.sharedWorkspace().openURL(NSURL(fileURLWithPath: path))
        }
    }
}

