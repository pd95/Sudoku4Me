//
//  AdaptiveVStack.swift
//  AdaptiveVStack
//
//  Created by Philipp on 31.07.21.
//

import SwiftUI

/// AdaptiveVStack is a VStack, which turns into an HStack whenever the vertical size becomes to comact.
///
/// Based on AdaptiveStack from HackingWithSwift but adjusted to use the `verticalSizeClass`
/// https://www.hackingwithswift.com/quick-start/swiftui/how-to-automatically-switch-between-hstack-and-vstack-based-on-size-class
///
struct AdaptiveVStack<Content: View>: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let spacing: CGFloat?
    let content: () -> Content

    init(horizontalAlignment: HorizontalAlignment = .center, verticalAlignment: VerticalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        Group {
            if verticalSizeClass == .compact {
                HStack(alignment: verticalAlignment, spacing: spacing, content: content)
            } else {
                VStack(alignment: horizontalAlignment, spacing: spacing, content: content)
            }
        }
    }
}

struct AdaptiveStack_Previews: PreviewProvider {
    static var previews: some View {
        AdaptiveVStack {
            ZStack {
                Color.red.opacity(0.2)
                Text("Vertical when there's lots of space")
            }
            Text("but")
            ZStack {
                Color.blue.opacity(0.2)
                Text("Horizontal when space is restricted")
            }
        }
        //.environment(\.verticalSizeClass, .compact)
    }
}
