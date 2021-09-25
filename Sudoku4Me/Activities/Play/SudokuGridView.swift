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

    var body: some View {
        Basic9x9GridView(
            cellForPosition: { (row, column) in
                SudokuCellView(
                    cell: game.cell(at: (column, row)),
                    isHighlighted: highlightedRow == row || highlightedColumn == column,
                    tapAction: {
                        hightlightCell(column, row)
                    }
                )
            }
        )
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
