//
//  GameService.swift
//  WristSide
//
//  Created by Hoorya Rafiq on 2026-06-10.
//

import Foundation
import Combine

@MainActor
class GameService: ObservableObject {
    
    @Published var scoreboard: ScoreboardResponse?
    
    private var pollingTask: Task<Void, Never>?
    
    init() {
        startPolling()
    }
    
    private var pollingInterval: UInt64 {
        let state = scoreboard?.events.first?.status.type.state
        switch state {
        case "in": return 30_000_000_000
        case "pre": return 300_000_000_000
        default: return 300_000_000_000
        }
    }
    
    func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task {
            while !Task.isCancelled {
                await fetchGameData()
                
                let state = scoreboard?.events.first?.status.type.state
                if state == "post" {
                    break
                }
                
                try? await Task.sleep(nanoseconds: pollingInterval)
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
    
    func fetchGameData() async {
        print(Bundle.main.object(forInfoDictionaryKey: "SCOREBOARD_BASE_URL") as? String ?? "not found")
        
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "SCOREBOARD_BASE_URL") as? String,
              let url = URL(string: "https://\(baseURL)") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            scoreboard = try decoder.decode(ScoreboardResponse.self, from: data)
            
            print("Fetched: \(scoreboard?.events.first?.status.type.state ?? "none")")

        } catch {
            print("Failed to fetch game data: \(error)")
        }
    }
    
}
