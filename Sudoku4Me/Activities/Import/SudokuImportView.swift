//
//  SudokuImportView.swift
//  SudokuImportView
//
//  Created by Philipp on 11.08.21.
//

import SwiftUI

enum ImportCompletion {
    case abort
    case success(SudokuGame, UIImage)
}

struct SudokuImportView: View {

    let selectedImportOption: ImportSourceType
    let action: (ImportCompletion) -> Void

    @StateObject private var reader = SudokuGridReader()

    @State private var highlightedRow: Int?
    @State private var highlightedColumn: Int?

    @State private var showingErrorMessage = false

    var body: some View {
        NavigationView {
            if !reader.hasValidInputImage {
                ImagePicker(withSourceType: .photoLibrary, handler: processImage)
                    .ignoresSafeArea()
                    .navigationBarHidden(true)
            }
            else {
                AdaptiveVStack {
                    if highlightedRow == nil {
                        if let image = reader.scaledUIImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(1, contentMode: .fit)
                                .opacity(reader.gridRectangleObservation != nil ? 0.5 : 1)
                                .overlay(
                                    ZStack {
                                        if let rectangleObservation = reader.gridRectangleObservation,
                                           let shape = Quadrilateral(rectangleObservation: rectangleObservation) {
                                            shape
                                                .fill(Color.yellow.opacity(0.4))
                                                .gesture(
                                                    DragGesture()
                                                        .onChanged({ value in
                                                            print(value)
                                                        })
                                                )
                                            shape
                                                .stroke(.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                        }
                                    }
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }

                    Rectangle()
                        .strokeBorder()
                        .overlay(Group {
                            if let gridImage = reader.gridUIImage {
                                Image(uiImage: gridImage)
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fit)
                                    .opacity(reader.cellDetails.isEmpty ? 1 : 0.5)
                                    .overlay(
                                        SudokuGridView(
                                            game: reader.game,
                                            highlightedRow: $highlightedRow.animation(.linear),
                                            highlightedColumn: $highlightedColumn.animation(.linear)
                                        )
                                        .opacity(reader.cellDetails.isEmpty ? 0 : 1)
                                        .animation(.linear)
                                    )
                            }
                        })
                        .aspectRatio(1, contentMode: .fit)

                    Spacer()

                    if highlightedRow != nil {
                        CustomKeyboard(tapAction: setValue)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                }
                .padding()
                .navigationBarHidden(false)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button("Cancel", action: dismissView)
                        Button(action: reader.reset) {
                            Label(selectedImportOption.description, systemImage: selectedImportOption.symbolName)
                                .imageScale(.large)
                        }
                    }
                    ToolbarItemGroup(placement: .confirmationAction) {
                        Button("Start", action: startGame)
                    }
                }
                .onReceive(reader.objectWillChange) { reader in
                    print("🔴 reader updated")
                }
                .onReceive(reader.$error, perform: { error in
                    if error != nil {
                        showingErrorMessage = true
                    }
                })
                .alert(isPresented: $showingErrorMessage, content: {
                    Alert(title: Text("An error occured"), message: Text(reader.error?.localizedDescription ?? "Unknown error"), dismissButton: .cancel())
                })
            }
        }
    }

    private func dismissView() {
        action(.abort)
    }

    private func startGame() {
        print("startGame")
        action(.success(reader.game, reader.gridUIImage!))
    }

    private func processImage(_ image: UIImage?) {
        print("processImage")
        guard let image = image,
              var ciimage = CIImage(image: image)
        else {
            dismissView()
            return
        }

        // Make sure we fix the image orientation if it's not yet "up"
        if image.imageOrientation != .up {
            ciimage = ciimage.oriented(image.imageOrientation.cgOrientation)
        }

        highlightedColumn = nil
        highlightedRow = nil

        reader.reset()
        reader.process(image: ciimage)
    }

    private func setValue(_ value: Int?) {
        guard let column = highlightedColumn,
              let row = highlightedRow
        else {
            return
        }
        withAnimation(.linear) {
            do {
                try reader.game.set(at: (column, row), value: value)
            } catch {
                print("error: \(error)")
            }
        }
    }
}

struct SudokuImportView_Previews: PreviewProvider {
    static var previews: some View {
        SudokuImportView(selectedImportOption: .photoLibrary, action: { _ in })
    }
}
