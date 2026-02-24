//
//  Created by Annie McCullagh on 2/10/26.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var showScanAlert = false
    @State private var scanMessage: String = ""

    private let rapidAPIKey = "9c07cd1562msh48d4542e5b4ee5fp17e7f6jsn9d3c9c8a5678"
    private let rapidAPIHost = "fashion4.p.rapidapi.com"
    private let rapidAPIURL = "https://fashion4.p.rapidapi.com/v2/results"

    var body: some View {
        VStack(spacing: 20) {
            Text("OutfitScan")
                .font(.largeTitle)
                .bold()

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

            Button {
                guard let imageData = selectedImageData else { return }
                sendToAPI(imageData)
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

    // MARK: - Multipart/form-data POST
    private func sendToAPI(_ imageData: Data) {
        guard let url = URL(string: rapidAPIURL) else { return }

        let boundary = "Boundary-\(UUID().uuidString)"

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(rapidAPIKey, forHTTPHeaderField: "x-rapidapi-key")
        request.setValue(rapidAPIHost, forHTTPHeaderField: "x-rapidapi-host")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Build multipart body
        var body = Data()
        let filename = "image.jpg"
        let mimeType = "image/jpeg"

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.scanMessage = "Error: \(error.localizedDescription)"
                    self.showScanAlert = true
                }
                return
            }

            guard let data = data,
                  let resultString = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    self.scanMessage = "No data received"
                    self.showScanAlert = true
                }
                return
            }

            DispatchQueue.main.async {
                self.scanMessage = resultString
                self.showScanAlert = true
            }
        }

        task.resume()
    }
}

// MARK: - Data append helper
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
