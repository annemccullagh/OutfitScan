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
    @State private var outfitResults: [OutfitSearchResult] = []

    private let rapidAPIKey = "600a16577dmshb9c34e78981189ap1cea92jsndb6e19553497"
    private let rapidAPIHost = "fashion4.p.rapidapi.com"
    private let rapidAPIURL = "https://fashion4.p.rapidapi.com/v2/results"

    private let ximilarToken = "c087e60960a3fcb0ec0f7e2da4dc59fd340e2557"
    private let ximilarProductColorsURL = "https://api.ximilar.com/dom_colors/product/v2/dominantcolor"

    private let searchAPIKey = "EP3aGav88AF4V2fA3FUgk9N8"
    private let searchAPIURL = "https://www.searchapi.io/api/v1/search"

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
                        outfitResults = []
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
                Label(isLoading ? "Searching..." : "Find Outfit", systemImage: isLoading ? "hourglass" : "sparkles")
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
        VStack(spacing: 8) {

            Text(result.displayTitle)
                .font(.title2)
                .bold()

            if !result.colorSummary.isEmpty {
                Text(result.colorSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button {
                showResultsSheet = true
            } label: {
                Text("View Outfits")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
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

                        sectionCard(title: "Outfit Inspiration Results") {
                            if outfitResults.isEmpty {
                                Text("No results found.")
                                    .foregroundStyle(.secondary)
                            } else {
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {

                                    ForEach(outfitResults) { outfit in
                                        VStack(alignment: .leading, spacing: 6) {

                                            if let thumbnail = outfit.thumbnail,
                                               let url = URL(string: thumbnail) {
                                                AsyncImage(url: url) { image in
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                } placeholder: {
                                                    ZStack {
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .fill(Color.gray.opacity(0.2))
                                                        ProgressView()
                                                    }
                                                }
                                                .frame(height: 140)
                                                .clipped()
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                            }

                                            Text(outfit.title)
                                                .font(.caption)
                                                .lineLimit(2)
                                        }
                                        .onTapGesture {
                                            if let url = URL(string: outfit.link) {
                                                UIApplication.shared.open(url)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        if !result.notes.isEmpty {
                            
                        }
                    } else {
                        Text("No results to display.")
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

    @MainActor
    private func analyzeImage(_ imageData: Data) async {
        isLoading = true
        errorMessage = nil
        outfitResults = []

        do {
            async let fashionResponse = sendToFashionAPI(imageData)
            async let colorResponse = sendToXimilarColorsAPI(imageData)

            let (fashionJSON, colorsJSON) = try await (fashionResponse, colorResponse)

            let parsedItems = parseFashionItems(from: fashionJSON)
            let parsedColors = parseDominantColors(from: colorsJSON)
            let combined = buildScanResult(
                items: parsedItems,
                colors: parsedColors,
                fashionJSON: fashionJSON,
                colorsJSON: colorsJSON
            )

            let searchQuery = "grey top outfit street style pinterest"
            let searchedOutfits = try await searchOutfits(query: searchQuery)

            result = combined
            outfitResults = searchedOutfits
            showResultsSheet = true
        } catch {
            errorMessage = error.localizedDescription
            showResultsSheet = false
        }

        isLoading = false
    }

    private func sendToFashionAPI(_ imageData: Data) async throws -> [String: Any] {
        guard !rapidAPIKey.isEmpty else {
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

    private func searchOutfits(query: String) async throws -> [OutfitSearchResult] {
        guard !searchAPIKey.isEmpty else {
            throw ScanError.serverError("Search API key missing")
        }

        guard var components = URLComponents(string: searchAPIURL) else {
            throw ScanError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "engine", value: "google_images"),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "num", value: "10")
            // Optional alternative to header auth:
            // URLQueryItem(name: "api_key", value: searchAPIKey)
        ]

        guard let url = components.url else {
            throw ScanError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(searchAPIKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data)

        let object = try JSONSerialization.jsonObject(with: data)
        guard let json = object as? [String: Any] else {
            throw ScanError.invalidJSON
        }

        print("SEARCH JSON:", json)

        return parseOutfitResults(from: json)
    }

    private func buildOutfitSearchQuery(items: [DetectedItem], colors: [DetectedColor]) -> String {
        let itemLabels = items.prefix(4).map { $0.label.lowercased() }
        let colorLabels = colors.prefix(2).map { $0.name.lowercased() }

        let queryParts = colorLabels + itemLabels
        let joined = queryParts.joined(separator: " ")

        if joined.isEmpty {
            return "fashion outfit inspiration"
        }

        return "\(joined) outfit street style fashion pinterest"
    }

    private func parseOutfitResults(from json: [String: Any]) -> [OutfitSearchResult] {
        var results: [OutfitSearchResult] = []

        if let imageResults = json["images"] as? [[String: Any]] {
            for item in imageResults.prefix(10) {
                let title = item["title"] as? String ?? "Untitled"

                let source = item["source"] as? [String: Any]
                let original = item["original"] as? [String: Any]

                let link = (source?["link"] as? String)
                    ?? (original?["link"] as? String)
                    ?? ""

                let snippet = source?["name"] as? String

                let thumbnail = item["thumbnail"] as? String
                    ?? (original?["link"] as? String)

                if !link.isEmpty {
                    results.append(
                        OutfitSearchResult(
                            title: title,
                            link: link,
                            snippet: snippet,
                            thumbnail: thumbnail
                        )
                    )
                }
            }
        }

        if let organicResults = json["organic_results"] as? [[String: Any]] {
            for item in organicResults.prefix(10) {
                let title = item["title"] as? String ?? "Untitled"
                let link = item["link"] as? String ?? ""
                let snippet = item["snippet"] as? String
                let thumbnail = item["thumbnail"] as? String

                if !link.isEmpty {
                    results.append(
                        OutfitSearchResult(
                            title: title,
                            link: link,
                            snippet: snippet,
                            thumbnail: thumbnail
                        )
                    )
                }
            }
        }

        return results
    }

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
            notes.append("Ximilar color detection is not active yet.")
            notes.append("Ximilar color detection is not active yet.")
        }
        if items.isEmpty {
            notes.append("The fashion API did not return clothing label.")
        }
        if searchAPIKey == "YOUR_SEARCHAPI_KEY" {
            notes.append("SearchAPI is not active yet")
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

struct OutfitSearchResult: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let link: String
    let snippet: String?
    let thumbnail: String?
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

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
