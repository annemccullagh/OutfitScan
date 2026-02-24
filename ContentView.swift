//
//  Created by Annie McCullagh on 2/10/26.
//

import SwiftUI
import PhotosUI
import UIKit

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isLoading = false
    @State private var showResultsSheet = false
    @State private var result: ScanResult?
    @State private var errorMessage: String?

   
    private let rapidAPIKey = "9c07cd1562msh48d4542e5b4ee5fp17e7f6jsn9d3c9c8a5678"
    private let rapidAPIHost = "fashion4.p.rapidapi.com"
    private let rapidAPIURL = "https://fashion4.p.rapidapi.com/v2/results"

    private let ximilarToken = "65b65e217db9b7cd29e86fe6da271fc840e6f582"
    private let ximilarProductColorsURL = "https://api.ximilar.com/dom_colors/product/v2/dominantcolor"

    var body: some View {
        VStack(spacing: 20) {
            Text("OutfitScan")
                .font(.largeTitle)
                .bold()

            imagePreview
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
                        result = nil
                        errorMessage = nil
                    }
                }
            }

            Button {
                guard let imageData = selectedImageData, !isLoading else { return }
                Task {
                    await analyzeImage(imageData)
                }
            } label: {
                Label(isLoading ? "Analyzing..." : "Analyze Outfit", systemImage: isLoading ? "hourglass" : "sparkles")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedImageData == nil || isLoading ? Color.gray.opacity(0.35) : Color.green)
                    .foregroundColor(selectedImageData == nil || isLoading ? .secondary : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
            .disabled(selectedImageData == nil || isLoading)

            if let result {
                summaryCard(result)
                    .padding(.horizontal)
            } else if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.top)
        .sheet(isPresented: $showResultsSheet) {
            resultsSheet
        }
    }

    private var imagePreview: some View {
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
    }

    @ViewBuilder
    private func summaryCard(_ result: ScanResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Summary")
                .font(.headline)

            Text(result.displayTitle)
                .font(.title3)
                .bold()

            if !result.items.isEmpty {
                Text("Detected Items: \(result.items.map(\.label).joined(separator: ", "))")
                    .foregroundStyle(.secondary)
            }

            if !result.colorSummary.isEmpty {
                Text("Colors: \(result.colorSummary)")
                    .foregroundStyle(.secondary)
            }

            Button("View Full Results") {
                showResultsSheet = true
            }
            .font(.headline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var resultsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let result {
                        sectionCard(title: "Search-Ready Description") {
                            Text(result.displayTitle)
                                .font(.title3)
                                .bold()
                        }

                        sectionCard(title: "Detected Clothing Attributes") {
                            if result.items.isEmpty {
                                Text("No clothing items were confidently extracted.")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(result.items) { item in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.label.capitalized)
                                            .font(.headline)
                                        if let confidence = item.confidence {
                                            Text("Confidence: \(Int(confidence * 100))%")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    if item.id != result.items.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }

                        sectionCard(title: "Dominant Colors") {
                            if result.colors.isEmpty {
                                Text("No color data returned.")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(result.colors) { color in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(color.name.capitalized)
                                            .font(.headline)
                                        if let percentage = color.percentage {
                                            Text("Approx. \(Int(percentage * 100))%")
                                                .foregroundStyle(.secondary)
                                        }
                                        if let hex = color.hex {
                                            Text("Hex: \(hex)")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    if color.id != result.colors.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }

                        if !result.notes.isEmpty {
                            sectionCard(title: "Notes") {
                                ForEach(result.notes, id: \.self) { note in
                                    Text("• \(note)")
                                }
                            }
                        }

                        sectionCard(title: "Raw JSON (for debugging)") {
                            Text(result.rawJSON)
                                .font(.system(.footnote, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    } else {
                        Text("No results yet.")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Photo Attributes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        showResultsSheet = false
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Main Analysis Pipeline
    @MainActor
    private func analyzeImage(_ imageData: Data) async {
        isLoading = true
        errorMessage = nil

        do {
            async let fashionResponse = sendToFashionAPI(imageData)
            async let colorResponse = sendToXimilarColorsAPI(imageData)

            let (fashionJSON, colorsJSON) = try await (fashionResponse, colorResponse)

            let parsedItems = parseFashionItems(from: fashionJSON)
            let parsedColors = parseDominantColors(from: colorsJSON)
            let combined = buildScanResult(items: parsedItems, colors: parsedColors, fashionJSON: fashionJSON, colorsJSON: colorsJSON)

            result = combined
            showResultsSheet = true
        } catch {
            errorMessage = error.localizedDescription
            showResultsSheet = false
        }

        isLoading = false
    }

    // MARK: - API Calls
    private func sendToFashionAPI(_ imageData: Data) async throws -> [String: Any] {
        guard rapidAPIKey != "YOUR_RAPIDAPI_KEY" else {
            throw ScanError.missingFashionKey
        }

        guard let url = URL(string: rapidAPIURL) else {
            throw ScanError.invalidURL
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(rapidAPIKey, forHTTPHeaderField: "x-rapidapi-key")
        request.setValue(rapidAPIHost, forHTTPHeaderField: "x-rapidapi-host")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let filename = "image.jpg"
        let mimeType = "image/jpeg"

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(imageData)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data)
        return try decodeJSONObject(from: data)
    }

    private func sendToXimilarColorsAPI(_ imageData: Data) async throws -> [String: Any] {
        guard ximilarToken != "YOUR_XIMILAR_TOKEN" else {
            // Return empty payload so the rest of the app still works even if the color API is not configured yet.
            return [:]
        }

        guard let url = URL(string: ximilarProductColorsURL) else {
            throw ScanError.invalidURL
        }

        let base64Image = imageData.base64EncodedString()
        let payload: [String: Any] = [
            "records": [["_base64": base64Image]],
            "colors": 3
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Token \(ximilarToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data)
        return try decodeJSONObject(from: data)
    }

    // MARK: - Parsing
    private func parseFashionItems(from json: [String: Any]) -> [DetectedItem] {
        var items: [DetectedItem] = []

        if let results = json["results"] as? [[String: Any]] {
            for result in results {
                if let entities = result["entities"] as? [[String: Any]] {
                    for entity in entities {
                        if let objects = entity["objects"] as? [[String: Any]] {
                            for object in objects {
                                if let nestedEntities = object["entities"] as? [[String: Any]] {
                                    for nested in nestedEntities {
                                        if let classes = nested["classes"] as? [String: Any] {
                                            for (label, rawConfidence) in classes {
                                                let confidence = rawConfidence as? Double
                                                items.append(DetectedItem(label: label, confidence: confidence))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Fallback parsing for flatter response shapes.
        if items.isEmpty,
           let objects = json["objects"] as? [[String: Any]] {
            for object in objects {
                if let label = object["label"] as? String {
                    let confidence = object["confidence"] as? Double
                    items.append(DetectedItem(label: label, confidence: confidence))
                } else if let classes = object["classes"] as? [String: Any] {
                    for (label, rawConfidence) in classes {
                        let confidence = rawConfidence as? Double
                        items.append(DetectedItem(label: label, confidence: confidence))
                    }
                }
            }
        }

        let deduplicated = Dictionary(grouping: items, by: { $0.label.lowercased() })
            .compactMap { _, group in
                group.max(by: { ($0.confidence ?? 0) < ($1.confidence ?? 0) })
            }
            .sorted(by: { ($0.confidence ?? 0) > ($1.confidence ?? 0) })

        return deduplicated
    }

    private func parseDominantColors(from json: [String: Any]) -> [DetectedColor] {
        guard
            let records = json["records"] as? [[String: Any]],
            let firstRecord = records.first,
            let dominant = firstRecord["_dominant_colors"] as? [String: Any]
        else {
            return []
        }

        var colors: [DetectedColor] = []

        if let simpleNames = dominant["color_names_simple"] as? [String: Double] {
            let hexList = dominant["rgb_hex_colors"] as? [String] ?? []
            let ordered = simpleNames.sorted { $0.value > $1.value }
            for (index, entry) in ordered.enumerated() {
                let hex = hexList.indices.contains(index) ? hexList[index] : nil
                colors.append(DetectedColor(name: entry.key, percentage: entry.value, hex: hex))
            }
            return colors
        }

        let names = dominant["color_names"] as? [String] ?? []
        let percentages = dominant["percentages"] as? [Double] ?? []
        let hexList = dominant["rgb_hex_colors"] as? [String] ?? []

        for index in names.indices {
            let percentage = percentages.indices.contains(index) ? percentages[index] : nil
            let hex = hexList.indices.contains(index) ? hexList[index] : nil
            colors.append(DetectedColor(name: names[index], percentage: percentage, hex: hex))
        }

        return colors
    }

    private func buildScanResult(items: [DetectedItem], colors: [DetectedColor], fashionJSON: [String: Any], colorsJSON: [String: Any]) -> ScanResult {
        let topColor = colors.first?.name
        let topItem = items.first?.label

        let displayTitle: String
        switch (topColor, topItem) {
        case let (color?, item?):
            displayTitle = "\(color.capitalized) \(item.capitalized)"
        case let (nil, item?):
            displayTitle = item.capitalized
        case let (color?, nil):
            displayTitle = color.capitalized + " Clothing Item"
        default:
            displayTitle = "Unable to build a clear clothing description"
        }

        var notes: [String] = []
        if ximilarToken == "YOUR_XIMILAR_TOKEN" {
            notes.append("Ximilar color detection is not active yet. Add your Ximilar token to enable dominant color results.")
        }
        if items.isEmpty {
            notes.append("The fashion API did not return a confidently parsed clothing label for this image.")
        }

        let mergedRaw: [String: Any] = [
            "fashion_response": fashionJSON,
            "color_response": colorsJSON
        ]

        return ScanResult(
            items: items,
            colors: colors,
            displayTitle: displayTitle,
            colorSummary: colors.map { color in
                if let percentage = color.percentage {
                    return "\(color.name.capitalized) (\(Int(percentage * 100))%)"
                }
                return color.name.capitalized
            }.joined(separator: ", "),
            notes: notes,
            rawJSON: prettyJSONString(from: mergedRaw)
        )
    }

    // MARK: - Helpers
    private func validateHTTPResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ScanError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw ScanError.serverError("HTTP \(httpResponse.statusCode): \(body)")
        }
    }

    private func decodeJSONObject(from data: Data) throws -> [String: Any] {
        let object = try JSONSerialization.jsonObject(with: data)
        guard let json = object as? [String: Any] else {
            throw ScanError.invalidJSON
        }
        return json
    }

    private func prettyJSONString(from object: Any) -> String {
        guard
            JSONSerialization.isValidJSONObject(object),
            let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
            let string = String(data: data, encoding: .utf8)
        else {
            return "Unable to pretty-print JSON."
        }
        return string
    }
}

// MARK: - Models
struct DetectedItem: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let confidence: Double?
}

struct DetectedColor: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let percentage: Double?
    let hex: String?
}

struct ScanResult {
    let items: [DetectedItem]
    let colors: [DetectedColor]
    let displayTitle: String
    let colorSummary: String
    let notes: [String]
    let rawJSON: String
}

enum ScanError: LocalizedError {
    case missingFashionKey
    case invalidURL
    case invalidResponse
    case invalidJSON
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .missingFashionKey:
            return "Add your RapidAPI Fashion key before testing the app."
        case .invalidURL:
            return "One of the API URLs is invalid."
        case .invalidResponse:
            return "The server returned an invalid response."
        case .invalidJSON:
            return "The server response was not valid JSON."
        case .serverError(let message):
            return message
        }
    }
}

// MARK: - Data Append Helper
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
