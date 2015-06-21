//
//  Printer.swift
//  AUPrint
//
//  Created by Johan K. Jensen on 21/06/2015.
//  Copyright © 2015 Johan K. Jensen. All rights reserved.
//

import Foundation

@objc
class MyPrinter: CustomStringConvertible {
    var name: String
    var location: String
    var url: String
    var driver: String
    
    var description: String {
        return "MyPrinter(\(name))"
    }

    init(name: String, location: String, url: String, driver: String) {
        self.name = name
        self.location = location
        self.url = url
        self.driver = driver
    }
    
    // Hack to make sorting with NSSortDescriptors working
    func valueForKeyPath(key: String) -> AnyObject? {
        switch key {
        case "name": return name
        case "location": return location
        case "url": return url
        case "driver": return driver
        default: return nil
        }
    }
}