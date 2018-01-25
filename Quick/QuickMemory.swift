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
    static var appWide = QuickMemory()
    
    func reset() {
        QuickMemory.shared = QuickMemory()
    }
    
    var stack : Array<Any> = []
    var heap : Dictionary<String, Any> = [:]
    
}
