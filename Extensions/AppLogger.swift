//
//  AppLogger.swift
//  WristSide
//
//  Created by Hoorya Rafiq on 2026-06-22.
//

import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.wristside"
    
    static let gameService = Logger(subsystem: subsystem, category: "GameService")
    
    static let claudeService = Logger(subsystem: subsystem, category: "ClaudeService")
    
    static let triggerDetector = Logger(subsystem: subsystem, category: "TriggerDetector")
    
    static let network = Logger(subsystem: subsystem, category: "Network")
}
