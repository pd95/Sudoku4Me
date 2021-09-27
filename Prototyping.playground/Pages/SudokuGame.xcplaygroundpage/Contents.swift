//: [Previous](@previous)

import Foundation

let example: [Int?] = [
    0,0,0,9,0,0,7,2,8,
    2,7,8,0,0,3,0,1,0,
    0,9,0,0,0,0,6,4,0,
    0,5,0,0,6,0,2,0,0,
    0,0,6,0,0,0,3,0,0,
    0,1,0,0,5,0,0,0,0,
    1,0,0,7,0,6,0,3,4,
    0,0,0,5,0,4,0,0,0,
    7,0,9,1,0,0,8,0,5,
]

let exampleComplete: [Int?] = [
    6,3,4,9,1,5,7,2,8,
    2,7,8,6,4,3,5,1,9,
    5,9,1,2,7,8,6,4,3,
    4,5,7,3,6,9,2,8,1,
    9,8,6,4,2,1,3,5,7,
    3,1,2,8,5,7,4,9,6,
    1,2,5,7,8,6,9,3,4,
    8,6,3,5,9,4,1,7,2,
    7,4,9,1,3,2,8,nil,5,  // 6 is missing
]

guard var game = try? SudokuGame(initialGrid: exampleComplete) else {
    fatalError("Invalid initial grid")
}

// Start game
try game.start()
print(game)

let remainingValues = game.valueCounts
    .map({ (value: $0.key, count: $0.value)})
    .sorted(by: {$0.value < $1.value })
    .filter({ $0.count < 9 })
print("remainingValues", remainingValues)

// Show all positions where a specific value is placed:
let valuePositions = game.valuePositions[6, default:[]]
print("valuePositions",valuePositions)

let (cols, rows): (columns: Set<Int>, rows: Set<Int>) = valuePositions.reduce(into: (columns: Set<Int>(), rows: Set<Int>())) { partialResult, position in
    if partialResult.columns.contains(position.column) == false {
        partialResult.columns.insert(position.column)
    }
    if partialResult.rows.contains(position.row) == false {
        partialResult.rows.insert(position.row)
    }
}
print("  columns", cols.sorted())
print("  rows", rows.sorted())


// Check valid values for a position
var position: SudokuGame.GridPosition = (column: 7, row: 8)
let allowedValue = game.allowedValues(for: position)

// Set the value
try? game.set(value: 6, at: position)
print(game)

// Recheck remaining values
_ = game.allowedValues(for: position)

game.checkDone()

//: [Next](@next)
