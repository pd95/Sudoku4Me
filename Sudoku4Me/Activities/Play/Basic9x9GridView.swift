//
//  Basic9x9GridView.swift
//  Sudoku4Me
//
//  Created by Philipp on 25.09.21.
//

import SwiftUI

struct Basic9x9GridView<SomeCellView:View>: View {

    var cellForPosition: (Int, Int) -> SomeCellView

    private let columns: [GridItem] = SudokuGame.positionRange.map({ _ in
        GridItem(.flexible(minimum: 3, maximum: 44), spacing: 0)
    })

    var body: some View {
        GeometryReader { proxy in
            LazyVGrid(
                columns: columns,
                spacing: 0,
                content: gridCells
            )
            .overlay(
                VStack(spacing: 0) {
                    ForEach(0..<3) { _ in
                        HStack(spacing: 0) {
                            ForEach(0..<3) { _ in
                                Rectangle()
                                    .stroke(lineWidth: 3)
                            }
                        }
                    }
                }
            )
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(minHeight: 150)
    }

    private func gridCells() -> some View {
        ForEach(0..<9) { row in
            ForEach(0..<9) { column in
                cellForPosition(row, column)
                    .border(Color.black, width: 0.5)
                    .aspectRatio(1, contentMode: .fill)
            }
        }
    }
}

struct GridBaseView_Previews: PreviewProvider {
    static var previews: some View {
        Basic9x9GridView(cellForPosition: { (row: Int, column: Int) in
            ZStack {
                [Color.red, Color.green, Color.blue, Color.yellow, Color.orange, Color.purple].randomElement()!

                let cell = SudokuGame.example.cell(at: (column, row))
                if let value = cell.value {
                    Text("\(value)")
                        .font(.headline)
                }
            }
        })
    }
}
