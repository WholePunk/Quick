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
    var archivedHeap : Dictionary<Int, Dictionary<String, Any>> = [:]
    var accessedSymbols : Dictionary<String, Array<String>> = [:]

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
        
        if accessedSymbols[key] == nil {
            accessedSymbols[key] = []
        }
        if !(accessedSymbols[key]!.contains(forKey)) {
            accessedSymbols[key]!.append(forKey)
        }

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
        
        if accessedSymbols[parserKey] == nil {
            accessedSymbols[parserKey] = []
        }
        if !(accessedSymbols[parserKey]!.contains(key)) {
            accessedSymbols[parserKey]!.append(key)
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
    
    func archiveHeapForParser(_ parser: Parser, onLine: Int) {
        
        let parserKey = parser.uuid
        
        guard heaps[parserKey] != nil else {
            return
        }
        
        let heapToArchive = heaps[parserKey]
        archivedHeap[onLine] = heapToArchive

    }
    
    func archivedHeap(onLine: Int) -> Dictionary<String, Any> {
        
        var heapToReturn : Dictionary<String, Any>?
        var testingLine = onLine
        
        while heapToReturn == nil && testingLine >= 0 {
            if archivedHeap[testingLine] != nil {
                heapToReturn = archivedHeap[testingLine]!
            }
            testingLine -= 1
        }
        
        if heapToReturn == nil {
            return [:]
        }
        return heapToReturn!
    }
    
    func resetHeapArchive() {
        archivedHeap = [:]
    }
    
    func symbolsAccessedByParser(_ parser: Parser) -> Array<String> {
        if accessedSymbols[parser.uuid] == nil {
            accessedSymbols[parser.uuid] = []
        }
        return accessedSymbols[parser.uuid]!
    }
    
}
