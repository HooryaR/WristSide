//
//  ContentView.swift
//  WristSide Watch App
//
//  Created by Hoorya Rafiq on 2026-06-09.
//

import SwiftUI

struct ContentView: View {
    @StateObject var gameService = GameService()
    
    var event: NBAEvent? { gameService.scoreboard?.events.first }
    var competition: NBACompetition? { event?.competitions.first }
    var home: NBACompetitors? { competition?.competitors.first(where: { $0.homeAway == "home" }) }
    var away: NBACompetitors? { competition?.competitors.first(where: { $0.homeAway == "away" }) }
    var scoreDiff: Int? {
        guard let h = Int(home?.score ?? ""), let a = Int(away?.score ?? "") else { return nil }
        return abs(h - a)
    }
    
    var body: some View {
        VStack {
            Text("Q\(event?.status.period ?? 0) · \(event?.status.displayClock ?? "--")")
                .bold()
                .font(Font.system(.title, design: .rounded))
            
            HStack {
                Text(competition?.series?.summary ?? "NBA Finals")
            }.foregroundStyle(.white)
            
            Text(competition?.notes?.first?.headline ?? "Finals")
                .font(Font.system(.footnote, design: .rounded))
                .foregroundStyle(.gray)
            
            Spacer()
            
            Text(gameService.insight)
                .font(Font.system(.caption, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.green)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(4)
                .padding()
            
            HStack {
                VStack {
                    Text(home?.team.abbreviation ?? "---")
                    Text(home?.score ?? "0")
                        .font(Font.system(.callout, design: .rounded))
                }.bold()
                
                Spacer()
                
                Text(scoreDiff.map { "\($0) pt" } ?? "--")
                    .bold()
                    .font(Font.system(.callout, design: .rounded))
                    .foregroundStyle(.red)
                
                Spacer()
                
                VStack {
                    Text(away?.team.abbreviation ?? "---")
                    Text(away?.score ?? "0")
                        
                        .font(Font.system(.callout, design: .rounded))
                }.bold()
            }
            .font(Font.system(.footnote, design: .rounded))
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
