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
}

struct Notes: Codable {
    let headline: String
}

struct Series: Codable {
    let summary: String
}
