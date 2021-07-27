//
//  ContentView.swift
//  Sudoku4Me
//
//  Created by Philipp on 19.07.21.
//

import SwiftUI

struct ContentView: View {
    @State private var game = SudokuGame.example
    @State private var highlightedRow: Int?
    @State private var highlightedColumn: Int?

    let columns: [GridItem] = SudokuGame.positionRange.map({ _ in
        GridItem(.flexible(minimum: 30, maximum: 44), spacing: 0)
    })

    var body: some View {
        VStack {
            Text("Sudoku!")
                .font(.largeTitle)
                .padding()

            LazyVGrid(
                columns: columns,
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

            if game.status == .initial {
                Button(action: startGame) {
                    Text("Start")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.accentColor)
                        )
                }
            }

            CustomKeyboard(tapAction: setValue)
                .transition(.move(edge: .bottom))
        }
        .padding()
    }

    private func gridCells() -> some View {
        ForEach(0..<9) { y in
            ForEach(0..<9) { x in
                SudokuCellView(
                    cell: game.cell(at: (x,y)),
                    isHighlighted: highlightedRow == y || highlightedColumn == x,
                    tapAction: {
                        hightlightCell(x,y)
                    }
                )
            }
        }
    }

    private func startGame() {
        withAnimation(.default) {
            do {
                try game.start()
            } catch {
                print("error: \(error)")
            }
        }
    }

    private func setValue(_ value: Int?) {
        guard let x = highlightedColumn,
              let y = highlightedRow
        else {
            return
        }
        withAnimation {
            do {
                try game.set(at: (x, y), value: value)
                game.checkDone()
            } catch {
                print("error: \(error)")
            }
        }
    }

    private func hightlightCell(_ x: Int, _ y: Int) {
        if x == highlightedColumn && y == highlightedRow {
            highlightedRow = nil
            highlightedColumn = nil
        }
        else {
            highlightedRow = y
            highlightedColumn = x
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
