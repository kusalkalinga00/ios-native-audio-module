//
//  AudioModulesPackage.swift
//  TestApp
//
//  Created by Kusal Kalinga on 2025-08-31.
//

import Foundation
import React

@objc(AudioModulesPackage)
class AudioModulesPackage: NSObject, RCTBridgeModule {
    static func moduleName() -> String! {
        return "AudioModulesPackage"
    }
    
    static func requiresMainQueueSetup() -> Bool {
        return false
    }
    
    // React Native will auto-link Swift modules, so no explicit registration is needed
}

