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
            .overlay(GeometryReader{ proxy in
                let width = proxy.size.width/3
                let height = proxy.size.height/3
                VStack(spacing: 0) {
                    ForEach(0..<3) { _ in
                        HStack(spacing: 0) {
                            ForEach(0..<3) { _ in
                                Rectangle()
                                    .stroke(lineWidth: 3)
                                    .frame(width: width, height: height)
                            }
                        }
                    }
                }
            })
        }
    }

    func gridCells() -> some View {
        ForEach(0..<9) { y in
            ForEach(0..<9) { x in
                ZStack {
                    Rectangle()
                        .stroke(Color.primary, lineWidth: 0.5)

                    let cell = game.cell(at: (x,y))
                    if let value = cell.value {
                        Text("\(value)")
                            .font(cell.editable ? Font.title2.bold() : Font.title2)
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
