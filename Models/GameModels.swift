//
//  GameModels.swift
//  WristSide
//
//  Created by Hoorya Rafiq on 2026-06-10.
//

struct ScoreboardResponse: Codable {
    let events: [NBAEvent]
}

struct NBAEvent: Codable {
    let id: String
    let status: Status
    let date: String?
    let competitions: [NBACompetition]
}

struct NBACompetition: Codable {
    let id: String
    let series: Series?
    let notes: [Notes]?
    let competitors: [NBACompetitors]
}

struct NBACompetitors: Codable {
    let id: String
    let score: String
    let homeAway: String
    let team: Team
}

struct Team: Codable {
    let id: String
    let abbreviation: String
    let displayName: String
}

struct Status: Codable {
    let period: Int
    let displayClock: String
    let type: StatusType
}

struct StatusType: Codable {
    let state: String
    let detail: String?
}

struct Notes: Codable {
    let headline: String
}

struct Series: Codable {
    let summary: String
}

struct SummaryResponse: Codable {
    let plays: [GamePlay]?
    let boxscore: GameBoxscore?
    let header: SummaryHeader?
}

struct GameBoxscore: Codable {
    let teams: [BoxscoreTeam]?
}

struct BoxscoreTeam: Codable {
    let team: Team?
    let statistics: [GameStatistic]?
}

struct GameStatistic: Codable {
    let name: String?
    let displayValue: String?
}

struct SummaryHeader: Codable {
    let competitions: [SummaryCompetition]?
}

struct SummaryCompetition: Codable {
    let status: SummaryStatus?
    let series: [Series]?
}

struct SummaryStatus: Codable {
    let type: StatusType?
}

struct GamePlay: Codable {
    let text: String?
    let period: PlayPeriod?
    let clock: PlayClock?
    let homeScore: Int?
    let awayScore: Int?
    let scoringPlay: Bool?
}

struct PlayPeriod: Codable {
    let number: Int?
}

struct PlayClock: Codable {
    let displayValue: String?
}
