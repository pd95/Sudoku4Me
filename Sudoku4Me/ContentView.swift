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

    @State private var showingImagePickerWithSource: UIImagePickerController.SourceType?
    @State private var selectedImage: UIImage?
    @StateObject private var reader = SudokuGridReader()
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
            VStack {

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
            .sheet(item: $showingImagePickerWithSource, content: { sourceType in
                ImagePicker(sourceType: sourceType, image: $selectedImage)
            })
            .onChange(of: selectedImage, perform: processImage)
            .onChange(of: reader.gridImage, perform: { _ in
                gridImage = reader.gridUIImage
            })
            .onChange(of: reader.game, perform: { newValue in
                if game.status == .initial {
                    game = newValue
                    clearHighlightedCell()
                }
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
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            Button(action: {
                                showingImagePickerWithSource = .camera
                            }) {
                                Image(systemName: "camera")
                                    .imageScale(.large)
                            }
                        }
                        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                            Button(action: {
                                showingImagePickerWithSource = .photoLibrary
                            }) {
                                Image(systemName: "photo")
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
        resetGame(reader.game)
    }

    private func resetGame(_ game: SudokuGame) {
        print("resetGame")
        withAnimation(.default) {
            self.game = game
            clearHighlightedCell()
        }
    }

    private func processImage(_ image: UIImage?) {
        print("processImage")
        guard let image = image,
              let ciimage = CIImage(image: image)
        else {
            return
        }

        resetGame(SudokuGame())
        reader.process(image: ciimage)
    }

    private func startGame() {
        print("startGame")

        // Make a copy if the game state
        reader.game = game

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
