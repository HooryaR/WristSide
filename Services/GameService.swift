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
    
    @Published var allGames: [NBAEvent] = []
    @Published var selectedGame: SelectedGame?
    @Published var scoreboard: ScoreboardResponse?
    @Published var summary: SummaryResponse?
    @Published var insight: String = "Waiting for a big moment..."
    
    private var pollingTask: Task<Void, Never>?
    private var triggerDetector = TriggerDetector()
    
    private let claudeService = ClaudeService()
    
    private var lastClaudeCallTime: Date = .distantPast
    
    init() {
        Task {
            await fetchAllGames()
        }
    }
    
    private var pollingInterval: UInt64 {
        let state = scoreboard?.events.first(where: { $0.id == selectedGame?.id })?.status.type.state
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
                
                let state = scoreboard?.events.first(where: { $0.id == selectedGame?.id })?.status.type.state
                
                if state == "in" {
                    await fetchSummaryData()
                    await checkForTriggers()
                }
                
                if state == "post" {
                    insight = "Game over!"
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
        guard let selected = selectedGame,
              let baseURL = Bundle.main.object(forInfoDictionaryKey: selected.league == "nba" ? "SCOREBOARD_BASE_URL" : "WNBA_SCOREBOARD_BASE_URL") as? String,
              let url = URL(string: "https://\(baseURL)") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            scoreboard = try decoder.decode(ScoreboardResponse.self, from: data)

        } catch {
            print("Failed to fetch game data: \(error)")
        }
    }
    
    func fetchSummaryData() async {
        guard let selected = selectedGame,
              let baseURL = Bundle.main.object(forInfoDictionaryKey: selected.league == "nba" ? "SUMMARY_BASE_URL" : "WNBA_SUMMARY_BASE_URL") as? String,
              let url = URL(string: "https://\(baseURL)?event=\(selected.id)") else { return }
            
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            summary = try decoder.decode(SummaryResponse.self, from: data)
            
        } catch {
            print("Failed to fetch summary data: \(error)")
        }
    }
    
    func fetchAllGames() async {
        var games: [NBAEvent] = []
        
        if let nbaURL = Bundle.main.object(forInfoDictionaryKey: "SCOREBOARD_BASE_URL") as? String,
           let url = URL(string: "https://\(nbaURL)") {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                var response = try decoder.decode(ScoreboardResponse.self, from: data)
                var nbaGames = response.events
                nbaGames = nbaGames.map { event in
                    var e = event
                    e.league = "nba"
                    return e
                }
                games.append(contentsOf: nbaGames)
            } catch {
                print("Failed to fetch NBA games: \(error)")
            }
        }
        
        if let wnbaURL = Bundle.main.object(forInfoDictionaryKey: "WNBA_SCOREBOARD_BASE_URL") as? String,
           let url = URL(string: "https://\(wnbaURL)") {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                var response = try decoder.decode(ScoreboardResponse.self, from: data)
                var wnbaGames = response.events
                wnbaGames = wnbaGames.map { event in
                    var e = event
                    e.league = "wnba"
                    return e
                }
                games.append(contentsOf: wnbaGames)
            } catch {
                print("Failed to fetch WNBA games: \(error)")
            }
        }
        
        allGames = games
    }
    
    func selectGame(_ game: NBAEvent) {
        selectedGame = SelectedGame(id: game.id, league: game.league)
        insight = "Waiting for a big moment..."
        triggerDetector = TriggerDetector()
        lastClaudeCallTime = .distantPast
        startPolling()
    }

    
    func checkForTriggers() async {

        guard let selected = selectedGame,
              let event = scoreboard?.events.first(where: { $0.id == selected.id }),
              let competition = event.competitions.first,
              let home = competition.competitors.first(where: { $0.homeAway == "home" }),
              let away = competition.competitors.first(where: { $0.homeAway == "away" }),
              let homeScore = Int(home.score),
              let awayScore = Int(away.score) else { return }
        
        let recentPlays = summary?.plays?.suffix(10).compactMap { $0.text } ?? []
        let seriesSummary = competition.series?.summary ?? ""
        
        if let trigger = triggerDetector.detect(
            homeScore: homeScore,
            awayScore: awayScore,
            homeTeam: home.team.abbreviation,
            awayTeam: away.team.abbreviation,
            period: event.status.period,
            clock: event.status.displayClock
        ) {
            let now = Date()
            if now.timeIntervalSince(lastClaudeCallTime) >= 120 {
                lastClaudeCallTime = now
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
}
