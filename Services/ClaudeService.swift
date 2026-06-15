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
        recentPlays: [String]
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
        }

        let recentPlaysText = recentPlays.prefix(10).joined(separator: "\n")

        let prompt = """
        NBA Finals live game context:
        \(homeTeam): \(homeScore) | \(awayTeam): \(awayScore)
        Period: Q\(period) | Clock: \(clock)
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
            "system": "You are a courtside NBA analyst. Respond with less than one sentence and under 12 words. Present tense. Be specific, name players. No punctuation at the end.",
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            print("Claude raw response: \(String(data: data, encoding: .utf8) ?? "unreadable")")
            let response = try JSONDecoder().decode(ClaudeResponse.self, from: data)
            return response.content.first?.text ?? ""
        } catch {
            print("Claude API error: \(error)")
            return ""
        }
        
    }
}
