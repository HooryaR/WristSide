//
//  ContentView.swift
//  WristSide Watch App
//
//  Created by Hoorya Rafiq on 2026-06-09.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Q4 - 4:22")
                .bold()
                .font(Font.system(.title, design: .rounded))
            
            HStack {
                Text("NYK 2")
                Text("-")
                Text("1 SAS")
            }.foregroundStyle(.white)
            
            Text("Finals")
                .font(Font.system(.footnote, design: .rounded))
                .foregroundStyle(.gray)
            
            Spacer()
            
            Text("Wemby 4 blocks - Knicks avoiding the paint")
                .font(Font.system(.caption, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.green)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)
            
            HStack {
                VStack {
                    Text("NYK")
                    Text("111")
                        .bold()
                        .font(Font.system(.callout, design: .rounded))
                }
                Spacer()
                
                Text("~ 10 pt")
                    .bold()
                    .font(Font.system(.footnote, design: .rounded))
                    .foregroundStyle(.red)
                
                Spacer()
                
                VStack {
                    Text("SAS")
                    Text("115")
                        .bold()
                        .font(Font.system(.callout, design: .rounded))
                }
            }
            .font(Font.system(.footnote, design: .rounded))
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
