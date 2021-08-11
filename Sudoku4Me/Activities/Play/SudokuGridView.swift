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
                SudokuCellView(
                    cell: game.cell(at: (column, row)),
                    isHighlighted: highlightedRow == row || highlightedColumn == column,
                    tapAction: {
                        hightlightCell(column, row)
                    }
                )
            }
        }
    }

    private func hightlightCell(_ column: Int, _ row: Int) {
        if column == highlightedColumn && row == highlightedRow {
            highlightedRow = nil
            highlightedColumn = nil
        }
        else {
            highlightedRow = row
            highlightedColumn = column
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
        //.frame(maxHeight: 250)
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
