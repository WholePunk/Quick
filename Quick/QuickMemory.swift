//
//  QuickMemory.swift
//  Quick
//
//  Created by Bob Warwick on 2018-01-14.
//  Copyright © 2018 Whole Punk Creators Ltd. All rights reserved.
//

import UIKit

class QuickMemory {

    static var shared = QuickMemory()
    
    var stack : Array<Any> = []
    var heaps : Dictionary<String, Dictionary<String, Any>> = [:]

    func reset() {
//        QuickMemory.shared = QuickMemory()
    }
    
    func setObject(_ object: Any, forKey: String, inHeapForParser: Parser?) {
        
        var key = "AppWide"
        if inHeapForParser != nil {
            key = inHeapForParser!.uuid
        }
        
        if heaps[key] == nil {
            heaps[key] = Dictionary<String, Any>()
        }
        
        heaps[key]![forKey] = object

    }
    
    func getObjectForKey(_ key: String, inHeapForParser: Parser?) -> Any {
        
        var parserKey = "AppWide"
        if inHeapForParser != nil {
            parserKey = inHeapForParser!.uuid
        }

        if heaps[parserKey] == nil {
            heaps[parserKey] = Dictionary<String, Any>()
        }
        
        var returnValue = heaps[parserKey]![key]
        if returnValue == nil {
            returnValue = ""
        }
        
        return returnValue!

    }
    
//    func heapForParser(_ parser: Parser) -> Dictionary<String, Any> {
//        if heaps[parser.uuid] == nil {
//            heaps[parser.uuid] = Dictionary<String, Any>()
//        }
//
//        return heaps[parser.uuid]
//    }
    
    
}
