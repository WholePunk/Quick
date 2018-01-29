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
    
    var stacks : Dictionary<String, Array<Any>> = [:]
    var heaps : Dictionary<String, Dictionary<String, Any>> = [:]

    func reset() {
//        QuickMemory.shared = QuickMemory()
    }
    
    let heapSemaphore = DispatchSemaphore(value: 1)
    
    func setObject(_ object: Any, forKey: String, inHeapForParser: Parser?) {
        
        heapSemaphore.wait()
        
        var key = "AppWide"
        if inHeapForParser != nil {
            key = inHeapForParser!.uuid
        }
        
        if heaps[key] == nil {
            heaps[key] = Dictionary<String, Any>()
        }
        
        heaps[key]![forKey] = object

        heapSemaphore.signal()
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
    
    let stackSemaphore = DispatchSemaphore(value: 1)
    
    func pushObject(_ object: Any, inStackForParser: Parser?) {
        
        stackSemaphore.wait()
        
        var key = "AppWide"
        if inStackForParser != nil {
            key = inStackForParser!.uuid
        }
        
        if stacks[key] == nil {
            stacks[key] = Array<Any>()
        }
        
        stacks[key]!.append(object)
        
        stackSemaphore.signal()
    }
    
    func popObject(inStackForParser: Parser?) -> Any {
        
        var parserKey = "AppWide"
        if inStackForParser != nil {
            parserKey = inStackForParser!.uuid
        }
        
        if stacks[parserKey] == nil {
            stacks[parserKey] = Array<Any>()
        }
        
        var returnValue = stacks[parserKey]!.popLast()
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
