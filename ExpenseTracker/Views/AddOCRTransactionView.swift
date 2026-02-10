import SwiftUI
import PhotosUI

struct AddOCRTransactionView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedItem: PhotosPickerItem?
    @State private var isProcessing = false
    @State private var ocrText: String?
    @State private var reviewTransaction: RawTransaction?

    let ocrService = OCRService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("Upload Receipt Image", systemImage: "doc")
                }

                if isProcessing {
                    ProgressView("Processing OCR…")
                }

                if let text = ocrText {
                    ScrollView {
                        Text(text)
                            .font(.caption)
                            .padding()
                    }
                }

                Spacer()
            }
            .navigationTitle("Add via OCR")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    await processImage(newItem)
                }
            }
            .sheet(item: $reviewTransaction) { raw in
                OCRReviewView(rawTransaction: raw, modelContext: modelContext)
            }
        }
    }

    private func processImage(_ item: PhotosPickerItem?) async {
        guard let item else { return }

        isProcessing = true
        defer { isProcessing = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { return }

            let text = try await ocrService.recognizeText(from: image)
            ocrText = text

            let raw = OCRParser.parse(text: text)
            ocrText = nil
            reviewTransaction = raw

        } catch {
            print("OCR failed:", error)
        }
    }
}
