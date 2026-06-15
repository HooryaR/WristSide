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
    
    var gameTimeDisplay: String {
        let state = event?.status.type.state
        switch state {
        case "in":
            return "Q\(event?.status.period ?? 0) · \(event?.status.displayClock ?? "--")"
        case "pre":
            return event?.status.type.detail ?? "Tip-off soon"
        case "post":
            return "Final"
        default:
            return "--"
        }
    }
    
    var gameTimeFont: Font {
        let state = event?.status.type.state
        switch state {
        case "in": return Font.system(.title3, design: .rounded)
        case "pre": return Font.system(.footnote, design: .rounded)
        case "post": return Font.system(.title3, design: .rounded)
         default: return Font.system(.footnote, design: .rounded)
        }
    }
    
    var pregameDisplay: String {
        guard let detail = event?.status.type.detail else { return "Tip-off soon" }
        
        let timePart: String
        if let atRange = detail.range(of: "at ") {
            timePart = String(detail[atRange.upperBound...])
                .replacingOccurrences(of: " EDT", with: "")
                .replacingOccurrences(of: " EST", with: "")
                .replacingOccurrences(of: " PDT", with: "")
                .replacingOccurrences(of: " PST", with: "")
        } else {
            timePart = ""
        }
        
        guard let dateString = event?.date,
              let date = ISO8601DateFormatter().date(from: dateString) else {
            return "Tip-off · \(timePart)"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        let shortDate = formatter.string(from: date)
        
        return "\(shortDate) · \(timePart)"
    }
    
    var body: some View {
        VStack {
            Text(gameTimeDisplay)
                .bold()
                .font(gameTimeFont)
            
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
