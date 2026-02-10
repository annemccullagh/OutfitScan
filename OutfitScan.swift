//
//  Created by Annie McCullagh on 2/10/26.
//

import SwiftUI
import PhotosUI

struct OutfitScan: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var showSubmittedAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text("OutfitScan")
                .font(.largeTitle)
                .bold()
            
            // Preview area
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
            
            // Pick photo
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
            
            // "Submit" button (just confirms for now)
            Button {
                showSubmittedAlert = true
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
            .alert("Submitted!", isPresented: $showSubmittedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your photo has been selected and submitted.")
            }
            
            Spacer()
        }
        .padding(.top)
    }
}
