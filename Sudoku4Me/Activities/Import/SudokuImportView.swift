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

    @State private var showingErrorMessage = false

    var body: some View {
        NavigationView {
            if !reader.hasValidInputImage {
                ImagePicker(sourceType: .photoLibrary, chooseAction: processImage)
                    .ignoresSafeArea()
                    .navigationBarHidden(true)
            }
            else {
                VStack {
                    if let image = reader.scaledUIImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .opacity(reader.gridRectangleObservation != nil ? 0.5 : 1)
                            .overlay(
                                Group {
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
                                            highlightedRow: .constant(nil),
                                            highlightedColumn: .constant(nil)
                                        )
                                            .opacity(reader.cellDetails.isEmpty ? 0 : 1)
                                    )
                            }
                        })
                        .aspectRatio(1, contentMode: .fit)

                    Spacer()
                }
                .padding()
                .toolbar {
                    ToolbarItemGroup(placement: .cancellationAction) {
                        Button("Cancel", action: dismissView)
                    }
                    ToolbarItemGroup(placement: .automatic) {
                        Button("Retake") {
                            reader.reset()
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

        reader.reset()
        reader.process(image: ciimage)
    }
}

struct SudokuImportView_Previews: PreviewProvider {
    static var previews: some View {
        SudokuImportView(selectedImportOption: .photoLibrary, action: { _ in })
    }
}
