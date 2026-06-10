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
    @Published var summary: SummaryResponse?
    @Published var insight: String = "Waiting for a big moment..."
    
    private var pollingTask: Task<Void, Never>?
    private var triggerDetector = TriggerDetector()
    
    private let claudeService = ClaudeService()
    
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
                
                if state == "in" {
                    await fetchSummaryData()
                    await checkForTriggers()
                }
                
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
    
    func fetchSummaryData() async {
        guard let eventId = scoreboard?.events.first?.id,
              let baseURL = Bundle.main.object(forInfoDictionaryKey: "SUMMARY_BASE_URL") as? String,
              let url = URL(string: "https://\(baseURL)?event=\(eventId)") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            summary = try decoder.decode(SummaryResponse.self, from: data)
            
            print("Summary fetched: \(summary?.plays?.first?.text ?? "no plays yet")")
            
        } catch {
            print("Failed to fetch summary data: \(error)")
        }
    }
    
    func checkForTriggers() async {
        guard let event = scoreboard?.events.first,
              let competition = event.competitions.first,
              let home = competition.competitors.first(where: { $0.homeAway == "home" }),
              let away = competition.competitors.first(where: { $0.homeAway == "away" }),
              let homeScore = Int(home.score),
              let awayScore = Int(away.score) else { return }
        
        let recentPlays = summary?.plays?.compactMap { $0.text } ?? []
        let seriesSummary = competition.series?.summary ?? ""
        
        if let trigger = triggerDetector.detect(
            homeScore: homeScore,
            awayScore: awayScore,
            homeTeam: home.team.abbreviation,
            awayTeam: away.team.abbreviation,
            period: event.status.period,
            clock: event.status.displayClock
        ) {
            insight = await claudeService.getInsight(
                trigger: trigger,
                homeTeam: home.team.abbreviation,
                awayTeam: away.team.abbreviation,
                homeScore: homeScore,
                awayScore: awayScore,
                period: event.status.period,
                clock: event.status.displayClock,
                seriesSummary: seriesSummary,
                recentPlays: recentPlays
            )
        }
    }
}
