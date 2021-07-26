//
//  CustomKeyboard.swift
//  CustomKeyboard
//
//  Created by Philipp on 25.07.21.
//

import SwiftUI

struct CustomKeyboard: View {
    static private let spacing: CGFloat = 5

    let tapAction: (Int?) -> Void

    var body: some View {
        VStack(spacing: Self.spacing) {
            ForEach(0..<3) { y in
                HStack(spacing: Self.spacing) {
                    ForEach(0..<3) { x in
                        let value = 1 + x + y * 3
                        let cell = SudokuGame.Cell(value: value, editable: false)
                        SudokuCellView(cell: cell, isHighlighted: false) {
                            tapAction(cell.value)
                        }
                        .frame(minWidth: 44, maxWidth: 60)
                    }
                }
            }
            SudokuCellView(cell: SudokuGame.Cell(value: nil, editable: false), isHighlighted: false) {
                tapAction(nil)
            }
            .frame(minWidth: 44, maxWidth: 60)
            .overlay(
                Image(systemName: "delete.left")
                    .imageScale(.large)
                    .font(.title2)
            )
        }
        .padding(Self.spacing)
    }
}


struct CustomKeyboard_Previews: PreviewProvider {
    static var previews: some View {
        CustomKeyboard(tapAction: { print("tapped on \(String(describing: $0))") })
            .frame(maxWidth: 400, maxHeight: 400)
    }
}
