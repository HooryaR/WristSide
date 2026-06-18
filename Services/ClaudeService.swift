//
//  ClaudeService.swift
//  WristSide
//
//  Created by Hoorya Rafiq on 2026-06-10.
//

import Foundation

class ClaudeService {
    
    func getInsight(
        trigger: GameTrigger,
        homeTeam: String,
        awayTeam: String,
        homeScore: Int,
        awayScore: Int,
        period: Int,
        clock: String,
        seriesSummary: String,
        recentPlays: [String],
        league: String
    ) async -> String {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String else { return "" }
        
        let triggerDescription: String
        switch trigger {
        case .scoringRun(let team, let points):
            triggerDescription = "\(team) just went on a \(points) point unanswered run"
        case .leadChange(let newLeader):
            triggerDescription = "\(newLeader) just took the lead"
        case .clutchTime:
            triggerDescription = "Clutch time — Q4 under 2 minutes within 5 points"
        case .quarterEnd(let period):
            triggerDescription = "End of Q\(period), summarise what just happened this quarter"
        case .threePointer(let player):
            triggerDescription = "\(player) just hit a three pointer"
        case .consecutiveThrees(let team):
            triggerDescription = "\(team) just hit back to back three pointers"
        case .bigBlock(let player):
            triggerDescription = "\(player) just recorded a big block"
        case .steal(let player):
            triggerDescription = "\(player) just got a steal"
        case .andOne(let player):
            triggerDescription = "\(player) just converted an and-one"
        case .comeback(let team, let deficit):
            triggerDescription = "\(team) has cut a \(deficit) point deficit to within 5"
        case .playerMilestone(let player, let points):
            triggerDescription = "\(player) just reached \(points) points in this game"
        case .scoringDrought(let team):
            triggerDescription = "\(team) has gone cold — no score in over 2 minutes"
        case .foulTrouble(let player, let fouls):
            triggerDescription = "\(player) is in foul trouble with \(fouls) fouls"
        case .tieGame(let isOT):
            triggerDescription = isOT ? "Game tied in overtime" : "Game tied in regulation"
        }
        
        let leagueContext: String
        switch league {
        case "wnba":
            leagueContext = "WNBA regular season game"
        case "nba":
            if seriesSummary.isEmpty {
                leagueContext = "NBA regular season game"
            } else {
                leagueContext = "NBA playoff game — \(seriesSummary)"
            }
        default:
            leagueContext = "basketball game"
        }
        
        let periodDisplay: String
        if period <= 4 {
            periodDisplay = "Q\(period)"
        } else if period == 5 {
            periodDisplay = "OT"
        } else {
            periodDisplay = "\(period - 4)OT"
        }

        let recentPlaysText = recentPlays.prefix(10).joined(separator: "\n")

        let prompt = """
        \(leagueContext)
        \(homeTeam): \(homeScore) | \(awayTeam): \(awayScore)
        Period: \(periodDisplay) | Clock: \(clock)
        Series: \(seriesSummary)
        Recent plays:
        \(recentPlaysText)
        Trigger: \(triggerDescription)
        Write ONE sentence under 12 words describing what just happened. Present tense. Name specific players if mentioned in plays. No punctuation at the end.
        """
        
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { return "" }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": "claude-sonnet-4-5",
            "max_tokens": 100,
            "system": "You are a courtside basketball expert analyst covering both NBA and WNBA. Respond with ONE sentence under 12 words. Present tense. Be specific, name players. No punctuation at the end.",
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let response = try JSONDecoder().decode(ClaudeResponse.self, from: data)
            return response.content.first?.text ?? ""
        } catch {
            print("Claude API error: \(error)")
            return ""
        }
        
    }
}
