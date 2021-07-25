//
//  SudokuGame.swift
//  SudokuGame
//
//  Created by Philipp on 25.07.21.
//

import Foundation

struct SudokuGame {
    static let positionRange = 0..<length
    static let valueRange = 1...9

    static private let length = 9
    static private let regionlength = 3

    static let example = try! SudokuGame(initialGrid: [
        0,0,0,9,0,0,7,2,8,
        2,7,8,0,0,3,0,1,0,
        0,9,0,0,0,0,6,4,0,
        0,5,0,0,6,0,2,0,0,
        0,0,6,0,0,0,3,0,0,
        0,1,0,0,5,0,0,0,0,
        1,0,0,7,0,6,0,3,4,
        0,0,0,5,0,4,0,0,0,
        7,0,9,1,0,0,8,0,5,
    ])

    typealias GridPosition = (x: Int, y: Int)
    typealias GridValue = Int?

    enum GameStatus {
        case initial
        case running
        case done
    }

    enum GameError: Error {
        case setNotAllowed
        case invalidPosition(GridPosition)
        case invalidValue(GridValue)
        case internalError
    }

    private var grid: [GridValue]
    private(set) var status: GameStatus

    // MARK: - Initializer
    init() {
        grid = Array(repeating: nil, count: Self.length * Self.length)
        status = .initial
    }

    init(initialGrid grid: [Int?]) throws {
        self.init()
        for y in Self.positionRange {
            for x in Self.positionRange {
                if let value = grid[y*Self.length + x], Self.valueRange.contains(value) {
                    try set(at: (x,y), value: value)
                }
            }
        }
    }


    // MARK: - Accessors
    func value(at position: GridPosition) -> GridValue {
        grid[position.y * Self.length + position.x]
    }

    mutating func set(at position: GridPosition, value: GridValue) throws {
        if status != .initial { throw GameError.setNotAllowed }

        if     Self.positionRange.contains(position.x) == false
            || Self.positionRange.contains(position.y) == false {
            throw GameError.invalidPosition(position)
        }

        if let value = value, Self.valueRange.contains(value) == false {
            throw GameError.invalidValue(value)
        }

        grid[position.y * Self.length + position.x] = value
    }

    // MARK: - Game status

    mutating func start() {
        status = .running
    }

    mutating func checkDone() -> Bool {
        var numberOfProblemsFound = 0

        for i in Self.positionRange {
            var array = gridRow(at: i)
            if !isValidSet(array) {
                print("Row \(i): \(array)")
                numberOfProblemsFound += 1
            }

            array = gridColumn(at: i)
            if !isValidSet(array) {
                print("Column \(i): \(array)")
                numberOfProblemsFound += 1
            }

            array = gridRegion(at: i)
            if !isValidSet(array) {
                print("Region \(i): \(array)")
                numberOfProblemsFound += 1
            }
        }

        if numberOfProblemsFound > 0 {
            print("\(numberOfProblemsFound) problems found")
            return false
        }

        print("Well done!")
        status = .done
        return true
    }

    // MARK: - Grid accessors

    private func gridRow(at index: Int) -> [GridValue] {
        Array(grid[index * Self.length..<(index+1) * Self.length])
    }

    private func gridColumn(at index: Int) -> [GridValue] {
        var array = [GridValue](repeating: nil, count: Self.length)

        for y in Self.positionRange {
            array[y] = grid[y * Self.length + index]
        }

        return array
    }

    private func gridRegion(at index: Int) -> [GridValue] {
        var array = [GridValue]()

        let xRegionIndex = (index % Self.regionlength)
        let yRegionIndex = index / Self.regionlength

        let xRange = Self.positionRange[xRegionIndex * Self.regionlength ..< xRegionIndex * Self.regionlength + Self.regionlength]
        let yRange = Self.positionRange[yRegionIndex * Self.regionlength ..< yRegionIndex * Self.regionlength + Self.regionlength]

        for y in yRange {
            for x in xRange {
                array.append(grid[y * Self.length + x])
            }
        }

        return array
    }

    // MARK: - Validation helper
    private func isValidSet(_ array: [GridValue]) -> Bool {
        subSetStatus(for: array) == .valid
    }

    enum SubSetStatus: Equatable {
        case valid
        case incomplete
        case missingValues(Set<GridValue>)
    }

    private func subSetStatus(for array: [GridValue]) -> SubSetStatus {
        let values = array.compactMap({$0})

        // Check whether the number of elements match
        if values.count != Self.length {
            print(">> is incomplete")
            return .incomplete
        }

        // Check whether all values appear in set
        let missingValues = Set(values).symmetricDifference(Self.valueRange)
        if missingValues.count > 0 {
            print(">> missing values: \(missingValues)")
            return .missingValues(missingValues)
        }

        return .valid
    }
}


// MARK: - CustomStringConvertible
extension SudokuGame: CustomStringConvertible {
    var description: String {
        var text = "SudokuGame(status: \(status), grid: [\n"
        var count = 0
        for value in grid {
            if let value = value {
                text += String(format: "%2d", value)
            }
            else {
                text += " -"
            }
            count += 1
            if count == Self.length {
                text += "\n"
                count = 0
            }
        }

        text += "])"
        return text
    }
}
