//
//  ContentView.swift
//  Sudoku4Me
//
//  Created by Philipp on 19.07.21.
//

import SwiftUI

struct ContentView: View {
    @State private var game = SudokuGame.example

    let rows: [GridItem] = SudokuGame.positionRange.map({ _ in
        GridItem(.flexible(minimum: 30, maximum: 44), spacing: 0)
    })

    var body: some View {
        VStack {
            Text("Sudoku!")
                .font(.largeTitle)
                .padding()

            LazyHGrid(
                rows: rows,
                spacing: 0,
                content: gridCells
            )
        }
    }

    func gridCells() -> some View {
        ForEach(0..<9) { y in
            ForEach(0..<9) { x in
                ZStack {
                    Rectangle()
                        .stroke(Color.primary)

                    if let value = game.value(at: (x,y)) {
                        Text("\(value)")
                            .font(.title2)
                    }
                }
                .aspectRatio(1, contentMode: .fill)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
