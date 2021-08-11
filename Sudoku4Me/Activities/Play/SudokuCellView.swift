//
//  SudokuCellView.swift
//  SudokuCellView
//
//  Created by Philipp on 25.07.21.
//

import SwiftUI

struct SudokuCellView: View {
    let cell: SudokuGame.Cell
    let isHighlighted: Bool
    let tapAction: () -> Void

    init(
        cell: SudokuGame.Cell,
        isHighlighted: Bool,
        tapAction: @escaping () -> Void
    ) {
        self.cell = cell
        self.isHighlighted = isHighlighted
        self.tapAction = tapAction
    }

    var body: some View {
        ZStack {
            Rectangle()
                .stroke(Color.primary, lineWidth: 0.5)
                .background(backgroundColor)

            // An invisible text placeholder...
            Text("88")
                .opacity(0)
                .overlay( Group {
                    // ...overlayed with the real text, if any
                    if let value = cell.value {
                        Text(value.description)
                            .frame(maxWidth: .infinity)
                            .transition(.identity)
                    }
                })
        }
        .font(cell.editable ? Font.title2 : Font.title2.bold())
        .contentShape(Rectangle())
        .aspectRatio(1, contentMode: .fit)
        .onTapGesture(perform: tapAction)
    }

    var backgroundColor: some View {
        isHighlighted ? Color.red.opacity(0.20) : Color.clear
    }
}


struct SudokuCellView_Previews: PreviewProvider {
    static var cells: [(cell: SudokuGame.Cell, highlight: Bool)] = [
        (.init(value: 1, editable: false), false),
        (.init(value: 2, editable: false), true),
        (.init(value: 3, editable: true), false),
        (.init(value: 4, editable: true), true),
    ]
    static var previews: some View {
        HStack {
            ForEach(Array(cells.indices), id: \.self) { index in
                let item = cells[index]
                SudokuCellView(cell: item.cell, isHighlighted: item.highlight, tapAction: {})
            }
            .frame(maxWidth: 44)
        }
    }
}
