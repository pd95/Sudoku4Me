//
//  ContentView.swift
//  Sudoku4Me
//
//  Created by Philipp on 19.07.21.
//

import SwiftUI

struct ContentView: View {
    @State private var previousGame = SudokuGame.example
    @State private var game = SudokuGame.example
    @State private var highlightedRow: Int?
    @State private var highlightedColumn: Int?
    @State private var showingStopConfirm = false

    @State private var sourceTypeForImport: ImportSourceType?
    @State private var gridImage: UIImage?

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
            AdaptiveVStack {
                SudokuGridView(
                    game: game,
                    highlightedRow: $highlightedRow,
                    highlightedColumn: $highlightedColumn
                )
                .background(Group {
                    if let image = gridImage {
                        Image(uiImage: image)
                            .resizable()
                            .opacity(game.status == .initial ? 0.3 : 0)
                            .padding(-5)
                    }
                })

                if game.status == .done {
                    Text("Well done!")
                        .font(.title)
                        .padding(.vertical, 20)
                }
                else {
                    CustomKeyboard(tapAction: setValue, values: allowedValues)
                        .transition(.move(edge: .bottom))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            .fullScreenCover(item: $sourceTypeForImport, content: { sourceType in
                SudokuImportView(selectedImportOption: sourceType, action: importedGame)
            })
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
                        ForEach(ImportSourceType.allCases.filter(\.isAvailable)) { sourceType in
                            Button(action: {
                                sourceTypeForImport = sourceType
                            }) {
                                Image(systemName: sourceType.symbolName)
                                    .imageScale(.large)
                            }
                        }
                    }
                }
            }
        }
    }

    private func clearHighlightedCell() {
        highlightedColumn = nil
        highlightedRow = nil
    }

    private func newGame() {
        print("newGame")
        resetGame(previousGame)
    }

    private func resetGame(_ game: SudokuGame) {
        print("resetGame")
        withAnimation(.default) {
            self.game = game
            clearHighlightedCell()
        }
    }

    private func startGame() {
        print("startGame")

        // Make a copy if the game state
        previousGame = game

        withAnimation(.default) {
            clearHighlightedCell()
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

    private func importedGame(_ completion: ImportCompletion) {
        sourceTypeForImport = nil // dismiss overlay
        if case .success(let game, let gridImage)  = completion {
            self.game = game
            self.gridImage = gridImage
            startGame()
        }
    }

    private func setValue(_ value: Int?) {
        guard let column = highlightedColumn,
              let row = highlightedRow
        else {
            return
        }
        do {
            try game.set(at: (column, row), value: value)
            game.checkDone()
        } catch {
            print("error: \(error)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
