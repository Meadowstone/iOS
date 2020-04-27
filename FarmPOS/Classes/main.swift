//
//  main.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/17/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation
import UIKit

UIApplicationMain(
    CommandLine.argc,
    UnsafeMutableRawPointer(CommandLine.unsafeArgv)
        .bindMemory(
            to: UnsafeMutablePointer<Int8>.self,
            capacity: Int(CommandLine.argc)),
    NSStringFromClass(FPAppDelegate.self),
    NSStringFromClass(FPAppDelegate.self)
)

