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


// Check valid values for a position
var position: SudokuGame.GridPosition = (x: 7, y: 8)
_ = game.allowedValues(for: position)

// Set the value
try? game.set(at: position, value: 6)
print(game)

// Recheck remaining values
_ = game.allowedValues(for: position)

game.checkDone()
print(game)



//: [Next](@next)
