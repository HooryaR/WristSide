//
//  TriggerDetector.swift
//  WristSide
//
//  Created by Hoorya Rafiq on 2026-06-10.
//

import Foundation

enum GameTrigger {
    case scoringRun(team: String, points: Int)
    case leadChange(newLeader: String)
    case clutchTime
    case quarterEnd(period: Int)
    case threePointer(player: String)
    case consecutiveThrees(team: String)
    case bigBlock(player: String)
    case steal(player: String)
    case andOne(player: String)
    case comeback(team: String, deficit: Int)
    case playerMilestone(player: String, points: Int)
    case scoringDrought(team: String)
    case foulTrouble(player: String, fouls: Int)
    case tieGame(isOT: Bool)
}

struct TriggerDetector {
    private var previousHomeScore: Int = 0
    private var previousAwayScore: Int = 0
    private var previousPeriod: Int = 0
    private var previousLeader: String = ""
    private var hasShownBlowout: Bool = false
    private var lastHomeScoreTime: Int = 0
    private var lastAwayScoreTime: Int = 0
    private var homeRunPoints: Int = 0
    private var awayRunPoints: Int = 0
    private var processedPlayTexts: Set<String> = []
    
    private func extractPlayer(from play: String) -> String {
        let components = play.components(separatedBy: " ")
        if components.count >= 2 {
            return "\(components[0]) \(components[1])"
        }
        return components.first ?? "Player"
    }

    mutating func detect(
        homeScore: Int,
        awayScore: Int,
        homeTeam: String,
        awayTeam: String,
        period: Int,
        clock: String,
        plays: [String]
    ) -> GameTrigger? {
        
        if period != previousPeriod && previousPeriod != 0 {
            previousPeriod = period
            return .quarterEnd(period: previousPeriod)
        }
        previousPeriod = period
        
        if abs(homeScore - awayScore) >= 20 && !hasShownBlowout {
            previousHomeScore = homeScore
            previousAwayScore = awayScore
            previousLeader = homeScore > awayScore ? homeTeam : awayTeam
            return .scoringRun(team: homeScore > awayScore ? homeTeam : awayTeam, points: abs(homeScore - awayScore))
        }

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

        if homePointsScored >= 4 && awayPointsScored == 0 {
            previousHomeScore = homeScore
            previousAwayScore = awayScore
            return .scoringRun(team: homeTeam, points: homePointsScored)
        }

        if awayPointsScored >= 4 && homePointsScored == 0 {
            previousHomeScore = homeScore
            previousAwayScore = awayScore
            return .scoringRun(team: awayTeam, points: awayPointsScored)
        }

        previousHomeScore = homeScore
        previousAwayScore = awayScore
        
        // scan new plays only
        let newPlays = plays.filter { !processedPlayTexts.contains($0) }
        
        for play in newPlays {
            processedPlayTexts.insert(play)
            let lower = play.lowercased()
            
            // three pointer
            if lower.contains("three point") || lower.contains("3-point") {
                if lower.contains("makes") {
                    let player = extractPlayer(from: play)
                    return .threePointer(player: player)
                }
            }
            
            // block
            if lower.contains("block") && !lower.contains("blocked shot") {
                let player = extractPlayer(from: play)
                return .bigBlock(player: player)
            }
            
            // steal
            if lower.contains("steals") {
                let player = extractPlayer(from: play)
                return .steal(player: player)
            }
            
            // and one
            if lower.contains("and one") || lower.contains("and-one") {
                let player = extractPlayer(from: play)
                return .andOne(player: player)
            }
            
            // foul trouble - count fouls for a player in recent plays
            if lower.contains("foul") && !lower.contains("team") {
                let player = extractPlayer(from: play)
                let foulCount = plays.filter {
                    $0.lowercased().contains("foul") && $0.lowercased().contains(player.lowercased())
                }.count
                if foulCount >= 3 {
                    return .foulTrouble(player: player, fouls: foulCount)
                }
            }
        }
        
        // tie game
        if homeScore == awayScore && homeScore > 0 {
            let isOT = period > 4
            if previousHomeScore != previousAwayScore {
                return .tieGame(isOT: isOT)
            }
        }
        
        // comeback
        let previousDiff = previousHomeScore - previousAwayScore
        let currentDiff = homeScore - awayScore
        if abs(previousDiff) >= 10 && abs(currentDiff) <= 5 && previousDiff.signum() == currentDiff.signum() {
            let comingBackTeam = currentDiff < 0 ? homeTeam : awayTeam
            return .comeback(team: comingBackTeam, deficit: abs(previousDiff))
        }

        return nil
    }

}
