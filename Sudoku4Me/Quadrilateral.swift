//
//  Quadrilateral.swift
//  Quadrilateral
//
//  Created by Philipp on 11.08.21.
//

import SwiftUI
import Vision

struct Quadrilateral: InsettableShape {

    var points: [CGPoint]
    var insetAmount: CGFloat = 0

    init(points: [CGPoint]) {
        guard points.count == 4 else {
            fatalError("Invalid list of points specified")
        }
        self.points = points
        self.points.append(points[0])
    }

    init(rectangleObservation: VNRectangleObservation) {
        let transform = CGAffineTransform.init(scaleX: 1, y: -1)
            .concatenating(.init(translationX: 0, y: 1))
        self.points = [
            rectangleObservation.topLeft.applying(transform),
            rectangleObservation.bottomLeft.applying(transform),
            rectangleObservation.bottomRight.applying(transform),
            rectangleObservation.topRight.applying(transform),
        ]
        self.points.append(points[0])
    }


    init(topLeft: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint, topRight: CGPoint) {
        points = [topLeft, bottomLeft, bottomRight, topRight, topLeft]
    }

    func inset(by amount: CGFloat) -> Self {
        var shape = self
        shape.insetAmount += amount
        return shape
    }

    func path(in rect: CGRect) -> Path {
        let scaleTransform = CGAffineTransform(scaleX: rect.width-2*insetAmount, y: rect.height-2*insetAmount)
        let offsetTransform = CGAffineTransform(translationX: insetAmount, y: insetAmount)

        let scaledPoints = points.map({ $0.applying(scaleTransform).applying(offsetTransform) })

        var path = Path()
        path.addLines(scaledPoints)
        return path
    }
}


struct Quadrilateral_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Quadrilateral(points: [
                .init(x: 0.2, y: 0.2),
                .init(x: 0.8, y: 0.2),
                .init(x: 0.9, y: 0.8),
                .init(x: 0.25, y: 0.75)
            ]).strokeBorder(style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))

            Quadrilateral(points: [
                .init(x: 0.1, y: 0.1),
                .init(x: 0.8, y: 0.2),
                .init(x: 0.9, y: 0.8),
                .init(x: 0.25, y: 0.75),
            ]).fill(LinearGradient(colors: [.red, .orange, .green, .blue, .purple], startPoint: .bottom, endPoint: .top))
        }
        .aspectRatio(contentMode: .fit)
        .frame(maxWidth: 200)
        .padding()
        .previewLayout(.fixed(width: 200, height: 200))
    }
}
