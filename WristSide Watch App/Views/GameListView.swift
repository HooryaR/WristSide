//
//  GameListView.swift
//  WristSide Watch App
//
//  Created by Hoorya Rafiq on 2026-06-15.
//

import SwiftUI

struct GameListView: View {
    @ObservedObject var gameService: GameService
    
    func gameSubtitle(_ event: NBAEvent) -> String {
        let state = event.status.type.state
        let home = event.competitions.first?.competitors.first(where: { $0.homeAway == "home" })
        let away = event.competitions.first?.competitors.first(where: { $0.homeAway == "away" })
        
        switch state {
        case "in":
            return "Q\(event.status.period) · \(event.status.displayClock)"
        case "post":
            return "\(away?.score ?? "0") - \(home?.score ?? "0") · Final"
        case "pre":
            if let atRange = event.status.type.detail?.range(of: "at ") {
                var timePart = String(event.status.type.detail![atRange.upperBound...])
                timePart = timePart
                    .replacingOccurrences(of: " EDT", with: "")
                    .replacingOccurrences(of: " EST", with: "")
                    .replacingOccurrences(of: " PDT", with: "")
                    .replacingOccurrences(of: " PST", with: "")
                return "Tonight · \(timePart)"
            }
            return event.status.type.detail ?? "Upcoming"
        default:
            return "--"
        }
    }
    
    func gameTitle(_ event: NBAEvent) -> String {
        let home = event.competitions.first?.competitors.first(where: { $0.homeAway == "home" })
        let away = event.competitions.first?.competitors.first(where: { $0.homeAway == "away" })
        return "\(away?.team.abbreviation ?? "---") vs \(home?.team.abbreviation ?? "---")"
    }
    
    var body: some View {
        NavigationStack {
            List(gameService.allGames, id: \.id) { game in
                NavigationLink(destination: ContentView(gameService: gameService)
                    .onAppear {
                        gameService.selectGame(game)
                    }
                ) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(gameTitle(game))
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.bold)
                            Spacer()
                            Text(game.league.uppercased())
                                .font(.system(.caption2, design: .rounded))
                                .fontWeight(.semibold)
                                //.font(.system(size: 9, weight: .medium))
                                .foregroundStyle(game.league == "nba" ? .orange : .red)
                        }
                        HStack {
                            if game.status.type.state == "in" {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 5, height: 5)
                            }
                            Text(gameSubtitle(game))
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Today")
        }
    }
}

#Preview {
    GameListView(gameService: GameService())
}
