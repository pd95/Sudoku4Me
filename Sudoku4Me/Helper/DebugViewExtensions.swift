//
//  DebugViewExtensions.swift
//  DebugViewExtensions
//
//  Created by Philipp on 26.06.21.
//

import SwiftUI

// https://www.swiftbysundell.com/articles/building-swiftui-debugging-utilities/
extension View {
    func debugAction(_ closure: () -> Void) -> Self {
        #if DEBUG
        closure()
        #endif

        return self
    }

    func debugPrint(_ value: Any) -> Self {
        debugAction { print(value) }
    }

    func debugModifier<T: View>(_ modifier: (Self) -> T) -> some View {
        #if DEBUG
        return modifier(self)
        #else
        return self
        #endif
    }

    func debugBorder(_ color: Color = .red, width: CGFloat = 1) -> some View {
        debugModifier {
            $0.border(color, width: width)
        }
    }

    func debugBackground(_ color: Color = .red) -> some View {
        debugModifier {
            $0.background(color)
        }
    }
}
