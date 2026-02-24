//
//  Created by Annie McCullagh on 2/10/26.
//

import SwiftUI
import PhotosUI
import Vision
import UIKit

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var showScanAlert = false
    @State private var scanMessage: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("OutfitScan")
                .font(.largeTitle)
                .bold()

            //preview of app
            Group {
                if let selectedImageData,
                   let uiImage = UIImage(data: selectedImageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 350)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 4)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                        .frame(height: 250)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 36))
                                Text("No photo selected")
                                    .foregroundStyle(.secondary)
                            }
                        )
                }
            }
            .padding(.horizontal)

            //let user pick a photo
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("Choose Photo", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.tint)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
            .onChange(of: selectedItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        selectedImageData = data
                    }
                }
            }

            //submit button
            Button {
                guard let imageData = selectedImageData,
                      let image = UIImage(data: imageData) else { return }
                scanImage(image)
            } label: {
                Label("Submit Photo", systemImage: "paperplane.fill")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedImageData == nil ? Color.gray.opacity(0.35) : Color.green)
                    .foregroundColor(selectedImageData == nil ? .secondary : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
            .disabled(selectedImageData == nil)

            Spacer()
        }
        .padding(.top)
        //attach the sheet to the whole screen (VStack), not inside it
        .sheet(isPresented: $showScanAlert) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Photo Attributes")
                    .font(.title2).bold()

                ScrollView {
                    Text(scanMessage.isEmpty ? "No results yet." : scanMessage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .textSelection(.enabled)
                }

                Button("Close") { showScanAlert = false }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding()
        }
    }

    //API
    private func scanImage(_ image: UIImage) {
        guard let ciImage = CIImage(image: image) else {
            print("Could not convert UIImage to CIImage.")
            return
        }

        let request = VNClassifyImageRequest { request, error in
            if let error = error {
                print("Image classification error: \(error.localizedDescription)")
                return
            }

            guard let observations = request.results as? [VNClassificationObservation] else {
                print("Request returned no observations.")
                return
            }

            let top = observations.prefix(5)
            let lines = top.map { obs in
                "\(obs.identifier) — \(Int(obs.confidence * 100))%"
            }

            DispatchQueue.main.async {
                self.scanMessage = lines.joined(separator: "\n")
                self.showScanAlert = true
            }
        }

        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])

        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform Vision request: \(error.localizedDescription)")
        }
    }

    private func processImage(_ image: UIImage) {
        scanImage(image)
    }
}
