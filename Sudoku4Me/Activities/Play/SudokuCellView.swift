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

            Text(String(cell.value ?? -1))
                .opacity(cell.value == nil ? 0 : 1)
                .minimumScaleFactor(0.5)
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
