//
//  ContentView.swift
//  Sudoku4Me
//
//  Created by Philipp on 19.07.21.
//

import SwiftUI

struct ContentView: View {
    @State private var game = SudokuGame.example
    @State private var highlightedRow: Int?
    @State private var highlightedColumn: Int?
    @State private var showingStopConfirm = false

    var allowedValues: Set<Int>? {
        guard game.status == .running else { return nil }

        guard let highlightedRow = highlightedRow,
              let highlightedColumn = highlightedColumn
        else {
            return nil
        }
        return game.allowedValues(for: (highlightedColumn, highlightedRow))
    }

    var body: some View {
        NavigationView {
            VStack {

                SudokuGridView(
                    game: game,
                    highlightedRow: $highlightedRow,
                    highlightedColumn: $highlightedColumn
                )

                if game.status == .done {
                    Text("Well done!")
                        .font(.title)
                        .padding(.vertical, 20)
                }
                else {
                    CustomKeyboard(tapAction: setValue, values: allowedValues)
                        .transition(.move(edge: .bottom))
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding()
            .alert(isPresented: $showingStopConfirm) {
                Alert(title: Text("Stop running game?"),
                      message: Text("Do you really want to loose the current game progress?"),
                      primaryButton: .default(Text("OK"), action: newGame),
                      secondaryButton: .cancel())
            }
            .navigationTitle("Sudoku!")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    switch game.status {
                    case .initial:
                        Button(action: startGame) {
                            Text("Start")
                        }
                    case .running:
                        Button(action: stopGame) {
                            Text("Stop")
                        }
                    case .done:
                        Button(action: newGame) {
                            Text("New")
                        }
                    }
                }
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    if game.status == .initial {
                        Button(action: scanPuzzle) {
                            Image(systemName: "camera")
                        }
                    }
                }
            }
        }
    }

    private func newGame() {
        game = .init()
        highlightedColumn = nil
        highlightedRow = nil
    }

    private func scanPuzzle() {
    }

    private func startGame() {
        withAnimation(.default) {
            do {
                try game.start()
            } catch {
                print("error: \(error)")
            }
        }
    }

    private func stopGame() {
        guard game.status == .running else {
            return
        }
        showingStopConfirm = true
    }

    private func setValue(_ value: Int?) {
        guard let x = highlightedColumn,
              let y = highlightedRow
        else {
            return
        }
        withAnimation {
            do {
                try game.set(at: (x, y), value: value)
                game.checkDone()
            } catch {
                print("error: \(error)")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
