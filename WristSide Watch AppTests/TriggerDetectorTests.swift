//
//  WristSide_Watch_AppTests.swift
//  WristSide Watch AppTests
//
//  Created by Hoorya Rafiq on 2026-06-09.
//

import Testing
@testable import WristSide_Watch_App

struct TriggerDetectorTests {
    
    @Test func scoringRunFiresWhenHomeTeamScores4Unanswered() {
        var detector = TriggerDetector()
        
        _ = detector.detect(
            homeScore: 12,
            awayScore: 10,
            homeTeam: "NYK",
            awayTeam: "SA",
            period: 2,
            clock: "5:00",
            plays: []
        )
        
        let trigger = detector.detect(
            homeScore: 16,
            awayScore: 10,
            homeTeam: "NYK",
            awayTeam: "SA",
            period: 2,
            clock: "3:00",
            plays: []
        )
        
        if case .scoringRun(let team, let points) = trigger {
            #expect(team == "NYK")
            #expect(points == 4)
        } else {
            Issue.record("Expected scoringRun trigger but got \(String(describing: trigger))")
        }
    }
    
    @Test func clutchTimeTriggerFires() {
        var detector = TriggerDetector()
        
        let trigger = detector.detect(
            homeScore: 100,
            awayScore: 98,
            homeTeam: "NYK",
            awayTeam: "SA",
            period: 4,
            clock: "1:30",
            plays: []
        )
        
        #expect(trigger != nil)
        if case .clutchTime = trigger {
        } else {
            Issue.record("Expected clutchTime trigger but got \(String(describing: trigger))")
        }
    }
    
    @Test func threePointerTriggerFiresFromPlayText() {
        var detector = TriggerDetector()
        
        let trigger = detector.detect(
            homeScore: 10,
            awayScore: 10,
            homeTeam: "NYK",
            awayTeam: "SA",
            period: 1,
            clock: "8:00",
            plays: ["Jalen Brunson makes 25-foot three point jumper"]
        )
        
        if case .threePointer(let player) = trigger {
            #expect(player == "Jalen Brunson")
        } else {
            Issue.record("Expected threePointer trigger but got \(String(describing: trigger))")
        }
    }
    
    @Test func samePlayDoesNotFireTwice() {
        var detector = TriggerDetector()
        let plays = ["Jalen Brunson makes 25-foot three point jumper"]
        
        _ = detector.detect(
            homeScore: 10,
            awayScore: 10,
            homeTeam: "NYK",
            awayTeam: "SA",
            period: 1,
            clock: "8:00",
            plays: plays
        )
        
        let trigger = detector.detect(
            homeScore: 10,
            awayScore: 10,
            homeTeam: "NYK",
            awayTeam: "SA",
            period: 1,
            clock: "7:00",
            plays: plays
        )
        
        #expect(trigger == nil)
    }
    
    @Test func stealTriggerFiresFromPlayText() {
        var detector = TriggerDetector()
        
        let trigger = detector.detect(
            homeScore: 10,
            awayScore: 10,
            homeTeam: "NYK",
            awayTeam: "SA",
            period: 1,
            clock: "8:00",
            plays: ["Jalen Brunson bad pass turnover (Victor Wembanyama steals)"]
        )
        
        if case .steal(let player) = trigger {
            #expect(!player.isEmpty)
        } else {
            Issue.record("Expected steal trigger but got \(String(describing: trigger))")
        }
    }
    
    @Test func tieGameTriggerFires() {
        var detector = TriggerDetector()
        
        // away leading first
        _ = detector.detect(
            homeScore: 98,
            awayScore: 100,
            homeTeam: "NYK",
            awayTeam: "SA",
            period: 3,
            clock: "3:00",
            plays: []
        )
        
        // scores tie
        let trigger = detector.detect(
            homeScore: 100,
            awayScore: 100,
            homeTeam: "NYK",
            awayTeam: "SA",
            period: 3,
            clock: "2:00",
            plays: []
        )
        
        if case .tieGame(let isOT) = trigger {
            #expect(isOT == false)
        } else {
            Issue.record("Expected tieGame trigger but got \(String(describing: trigger))")
        }
    }
    
    @Test func tieGameInOTFiresCorrectly() {
        var detector = TriggerDetector()
        
        _ = detector.detect(
            homeScore: 110,
            awayScore: 112,
            homeTeam: "NYK",
            awayTeam: "SA",
            period: 5,
            clock: "2:00",
            plays: []
        )
        
        let trigger = detector.detect(
            homeScore: 112,
            awayScore: 112,
            homeTeam: "NYK",
            awayTeam: "SA",
            period: 5,
            clock: "1:00",
            plays: []
        )
        
        if case .tieGame(let isOT) = trigger {
            #expect(isOT == true)
        } else {
            Issue.record("Expected tieGame OT trigger but got \(String(describing: trigger))")
        }
    }
    
    @Test func quarterEndTriggerFires() {
        var detector = TriggerDetector()
        
        _ = detector.detect(
            homeScore: 28,
            awayScore: 30,
            homeTeam: "NYK",
            awayTeam: "SA",
            period: 1,
            clock: "0:00",
            plays: []
        )
        
        let trigger = detector.detect(
            homeScore: 28,
            awayScore: 30,
            homeTeam: "NYK",
            awayTeam: "SA",
            period: 2,
            clock: "12:00",
            plays: []
        )
        
        if case .quarterEnd(let period) = trigger {
            #expect(period == 1)
        } else {
            Issue.record("Expected quarterEnd trigger but got \(String(describing: trigger))")
        }
    }
    
    @Test func foulTroubleTriggerFires() {
        var detector = TriggerDetector()
        
        let plays = [
            "Karl-Anthony Towns personal foul",
            "Karl-Anthony Towns shooting foul",
            "Karl-Anthony Towns offensive foul"
        ]
        
        let trigger = detector.detect(
            homeScore: 10,
            awayScore: 10,
            homeTeam: "NYK",
            awayTeam: "SA",
            period: 2,
            clock: "5:00",
            plays: plays
        )
        
        if case .foulTrouble(let player, let fouls) = trigger {
            #expect(player.contains("Karl-Anthony"))
            #expect(fouls >= 3)
        } else {
            Issue.record("Expected foulTrouble trigger but got \(String(describing: trigger))")
        }
    }
}
