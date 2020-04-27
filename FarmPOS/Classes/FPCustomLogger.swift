//
//  FPCustomLogger.swift
//  Farm POS
//
//  Created by Vladimir Stepanchenko on 10/23/15.
//  Copyright (c) 2015 Eugene Reshetov. All rights reserved.
//

import Foundation

class FPCustomLogger {
    class func writeLogToFile(_ logString: String) {
        let f = FileManager.default
        if let u = try? f.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            let fileUrl = u.appendingPathComponent("cardFlightLog.txt")
            
            // Timestamp
            let fullLogString = "\(Date()): \(logString) \n"
            
            let data = fullLogString.data(using: String.Encoding.utf8, allowLossyConversion: false)!
            
            if f.fileExists(atPath: fileUrl.path) {
                if let fileHandle = try? FileHandle(forWritingTo: fileUrl) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            }
            else {
                try? data.write(to: fileUrl, options: .atomic)
            }
        }
    }
    
    class func startLogWrite(_ logString: String) {
        let f = FileManager.default
        if let u = try? f.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            let fileUrl = u.appendingPathComponent("cardFlightLog.txt")
            try? logString.write(to: fileUrl, atomically: true, encoding: .utf8)
        }
    }
}
