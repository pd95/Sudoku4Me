//
//  SudokuGame.swift
//  SudokuGame
//
//  Created by Philipp on 25.07.21.
//

import Foundation

struct SudokuGame: Hashable {
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

    static let example2 = try! SudokuGame(initialGrid: [
        6,3,4,9,1,5,7,2,8,
        2,7,8,6,4,3,5,1,0,
        5,9,1,2,7,8,6,4,3,
        4,5,7,3,6,9,2,8,1,
        9,8,6,4,2,1,3,5,7,
        3,1,2,8,5,7,4,9,6,
        1,2,5,7,8,6,9,3,4,
        8,6,3,5,9,4,1,7,2,
        7,4,9,1,3,2,8,6,5,
    ])

    typealias GridPosition = (column: Int, row: Int)
    typealias GridValue = Int?

    struct Cell: Hashable {
        var value: GridValue = nil
        var editable: Bool = true
    }

    enum GameStatus: Hashable {
        case initial
        case running
        case done
    }

    enum GameError: Error {
        case invalidGameStatus(GameStatus)
        case invalidPosition(GridPosition)
        case invalidValue(GridValue)
        case cellNotEditable
        case internalError
    }

    private var grid: [Cell]
    private(set) var status: GameStatus

    // MARK: - Initializer
    init() {
        grid = Array(repeating: Cell(), count: Self.length * Self.length)
        status = .initial
    }

    init(initialGrid grid: [Int?]) throws {
        self.init()
        for row in Self.positionRange {
            for column in Self.positionRange {
                if let value = grid[row*Self.length + column], Self.valueRange.contains(value) {
                    try set(at: (column,row), value: value)
                }
            }
        }
    }


    // MARK: - Accessors
    func cell(at position: GridPosition) -> Cell {
        grid[position.row * Self.length + position.column]
    }

    func value(at position: GridPosition) -> GridValue {
        cell(at: position).value
    }

    mutating func set(at position: GridPosition, value: GridValue) throws {

        if     Self.positionRange.contains(position.column) == false
            || Self.positionRange.contains(position.row) == false {
            throw GameError.invalidPosition(position)
        }

        if let value = value, Self.valueRange.contains(value) == false {
            throw GameError.invalidValue(value)
        }

        let offset = position.row * Self.length + position.column
        if status == .running {
            if grid[offset].editable == false {
                throw GameError.cellNotEditable
            }
        }
        else if status != .initial {
            throw GameError.invalidGameStatus(status)
        }

        grid[offset].value = value
    }

    func allowedValues(for position: GridPosition) -> Set<Int> {
        let setValues = gridRow(at: position.row)
            + gridColumn(at: position.column)
            + gridRegion(xRegion: position.column/SudokuGame.regionlength, yRegion: position.row/SudokuGame.regionlength)

        let validValues = Set(SudokuGame.valueRange).symmetricDifference(setValues.compactMap({$0}))
        print("remaining", validValues)

        return validValues
    }

    var valueCounts: [Int: Int] {
        let valueCounts = grid.reduce(into: [Int:Int]()) { partialResult, cell in
            if let value = cell.value {
                partialResult[value, default: 0] += 1
            }
        }
        return valueCounts
    }

    var valuePositions: [Int: [GridPosition]] {
        let valuePositions = grid.enumerated()
            .reduce(into: [Int:[GridPosition]]()) { (partialResult, element) in
                let (index, cell) = element
                if let value = cell.value {
                    partialResult[value, default: []].append((index % Self.length, index / Self.length))
                }
        }
        return valuePositions
    }

    // MARK: - Game status

    mutating func start() throws {
        if status != .initial { throw GameError.invalidGameStatus(status) }

        // Make all populated cells non-editable
        grid = grid.map({ cell in
            if let value = cell.value {
                return Cell(value: value, editable: false)
            }
            return cell
        })

        status = .running
    }

    @discardableResult
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
        Array(grid[index * Self.length..<(index+1) * Self.length].map(\.value))
    }

    private func gridColumn(at index: Int) -> [GridValue] {
        var array = [GridValue](repeating: nil, count: Self.length)

        for row in Self.positionRange {
            array[row] = grid[row * Self.length + index].value
        }

        return array
    }

    private func gridRegion(at index: Int) -> [GridValue] {
        gridRegion(xRegion: index % Self.regionlength, yRegion: index / Self.regionlength)
    }

    private func gridRegion(xRegion: Int, yRegion: Int) -> [GridValue] {
        var array = [GridValue]()

        let columnRange = Self.positionRange[xRegion * Self.regionlength ..< xRegion * Self.regionlength + Self.regionlength]
        let rowRange = Self.positionRange[yRegion * Self.regionlength ..< yRegion * Self.regionlength + Self.regionlength]

        for row in rowRange {
            for column in columnRange {
                array.append(grid[row * Self.length + column].value)
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
        for cell in grid {
            if let value = cell.value {
                text += String(format: "%2d", value) + (cell.editable ? " " : "*")
            }
            else {
                text += " - "
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
