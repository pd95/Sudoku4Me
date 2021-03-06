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
    let values: Set<Int>

    init(tapAction: @escaping (Int?) -> Void, values: Set<Int>? = nil) {
        self.tapAction = tapAction
        self.values = values ?? Set(SudokuGame.valueRange)
    }

    var body: some View {
        VStack(spacing: Self.spacing) {
            ForEach(0..<3) { row in
                HStack(spacing: Self.spacing) {
                    ForEach(0..<3) { column in
                        let value = 1 + column + row * 3
                        Button(action: { tapAction(value) }) {
                            Text(String(value))
                                .font(.title2.bold())
                        }
                        .disabled(values.contains(value) == false)
                    }
                }
            }
            Button(action: { tapAction(nil) }) {
                Image(systemName: "delete.left")
                    .font(.title2)
            }
        }
        .buttonStyle(CustomButtonStyle())
        .padding(Self.spacing)
    }


    struct CustomButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .frame(minWidth: 44, minHeight: 44)
                .aspectRatio(contentMode: .fill)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke()
                )
                .foregroundColor(.accentColor.opacity(configuration.isPressed ? 0.5 : 1))
        }
    }
}


struct CustomKeyboard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CustomKeyboard(tapAction: { print("tapped on \(String(describing: $0))") })
            CustomKeyboard(tapAction: { print("tapped on \(String(describing: $0))") }, values: Set([2,3,5,7,8,9]))
        }
        .previewLayout(.sizeThatFits)
    }
}
