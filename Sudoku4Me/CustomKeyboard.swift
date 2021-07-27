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
                        Button(action: { tapAction(value) }) {
                            Text(String(value))
                                .font(.title2.bold())
                        }
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
        CustomKeyboard(tapAction: { print("tapped on \(String(describing: $0))") })
            .frame(maxWidth: 400, maxHeight: 400)
    }
}
