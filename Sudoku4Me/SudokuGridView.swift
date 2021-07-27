//
//  SudokuGridView.swift
//  SudokuGridView
//
//  Created by Philipp on 27.07.21.
//

import SwiftUI

struct SudokuGridView: View {
    let game: SudokuGame

    @Binding var highlightedRow: Int?
    @Binding var highlightedColumn: Int?

    let columns: [GridItem] = SudokuGame.positionRange.map({ _ in
        GridItem(.flexible(minimum: 30, maximum: 44), spacing: 0)
    })

    var body: some View {
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


struct SudokuGridView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SudokuGridView(game: .example,
                           highlightedRow: .constant(nil),
                           highlightedColumn: .constant(nil))
            SudokuGridView(game: .example2,
                           highlightedRow: .constant(1),
                           highlightedColumn: .constant(8))
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
