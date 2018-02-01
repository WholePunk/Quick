//
//  QuickError.swift
//  Quick
//
//  Created by Bob Warwick on 2018-01-14.
//  Copyright © 2018 Whole Punk Creators Ltd. All rights reserved.
//

import UIKit

class QuickError {

    static var shared = QuickError()
    private var errorMessage = ""
    private var errorLine = -1
    var callback : ((_ message: String)->())?
    
    func setCallback(_ passedCallback: @escaping (_ message: String)->()) {
        callback = passedCallback
    }
    
    func resetError() {
        errorMessage = ""
        errorLine = -1
    }
    
    func errorHappened() -> Bool {
        return errorLine != -1
    }
    
    func setErrorMessage(_ message : String, withLine: Int) {
        
        guard errorLine == -1 else {
            return
        }
        
        errorMessage = message
        errorLine = withLine
        
        if errorLine == -2 {
            callback?("\(errorMessage)")
        } else {
            callback?("\(errorMessage) on line \(errorLine + 1)")
        }
        
    }
    
}
