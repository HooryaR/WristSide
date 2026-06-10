//
//  TriggerDetector.swift
//  WristSide
//
//  Created by Hoorya Rafiq on 2026-06-10.
//

enum GameTrigger {
    case scoringRun(team: String, points: Int)
    case leadChange(newLeader: String)
    case clutchTime
}

struct TriggerDetector {
    private var previousHomeScore: Int = 0
    private var previousAwayScore: Int = 0
    private var previousLeader: String = ""

    mutating func detect(
        homeScore: Int,
        awayScore: Int,
        homeTeam: String,
        awayTeam: String,
        period: Int,
        clock: String
    ) -> GameTrigger? {

        let parts = clock.split(separator: ":").map { Int($0) ?? 0 }
        let totalSeconds = (parts.first ?? 0) * 60 + (parts.last ?? 0)

        let scoreDiff = abs(homeScore - awayScore)
        if period == 4 && totalSeconds <= 120 && scoreDiff <= 5 {
            previousHomeScore = homeScore
            previousAwayScore = awayScore
            previousLeader = homeScore > awayScore ? homeTeam : awayTeam
            return .clutchTime
        }
        
        let currentLeader = homeScore > awayScore ? homeTeam : awayTeam

        if previousLeader != "" && currentLeader != previousLeader {
            previousLeader = currentLeader
            return .leadChange(newLeader: currentLeader)
        }

        previousLeader = currentLeader
        
        let homePointsScored = homeScore - previousHomeScore
        let awayPointsScored = awayScore - previousAwayScore

        if homePointsScored >= 6 && awayPointsScored == 0 {
            previousHomeScore = homeScore
            previousAwayScore = awayScore
            return .scoringRun(team: homeTeam, points: homePointsScored)
        }

        if awayPointsScored >= 6 && homePointsScored == 0 {
            previousHomeScore = homeScore
            previousAwayScore = awayScore
            return .scoringRun(team: awayTeam, points: awayPointsScored)
        }

        previousHomeScore = homeScore
        previousAwayScore = awayScore

        return nil
    }

}
