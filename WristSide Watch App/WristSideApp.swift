//
//  WristSideApp.swift
//  WristSide Watch App
//
//  Created by Hoorya Rafiq on 2026-06-09.
//

import SwiftUI

@main
struct WristSide_Watch_AppApp: App {
    @StateObject var gameService = GameService()
    
    var body: some Scene {
        WindowGroup {
            GameListView(gameService: gameService)
        }
    }
}
