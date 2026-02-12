import SwiftUI
import VisionKit
import PhotosUI
import Vision

struct ScanReceiptView: View {

    @State private var showCamera = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var scannedImage: UIImage?
    @State private var rawTransaction: RawTransaction?
    @State private var isProcessing = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                Button {
                    showCamera = true
                } label: {
                    Label("Scan with Camera(Not tested)", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isProcessing)

                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images
                ) {
                    Label("Upload Receipt Image", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isProcessing)
                
                if isProcessing {
                    ProgressView("Processing image...")
                        .padding()
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Scan Receipt")
            .sheet(isPresented: $showCamera) {
                CameraView(image: $scannedImage)
            }
            .onChange(of: scannedImage) { oldValue, newValue in
                if let image = newValue {
                    Task {
                        isProcessing = true
                        await runOCR(on: image)
                        isProcessing = false
                    }
                }
            }
            .onChange(of: selectedItem) { oldValue, newValue in
                if newValue != nil {
                    Task {
                        isProcessing = true
                        await processImage(from: newValue)
                        isProcessing = false
                        selectedItem = nil // Reset for next selection
                    }
                }
            }
            .sheet(item: $rawTransaction) { raw in
                NavigationStack {
                    OCRReviewView(rawTransaction: raw)
                }
            }
        }
    }
}

private extension ScanReceiptView {

    func processImage(from item: PhotosPickerItem?) async {
        guard let item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                let resized = resizeImage(image, maxDimension: 1024)
                await runOCR(on: resized)
            }
        } catch {
            print("Error loading image: \(error)")
        }
    }

    func runOCR(on image: UIImage?) async {
        guard let image else { return }
        
        print("🔍 Starting OCR on image...")
        
        // Step 1: Extract text from image using Vision
        let extractedText = await extractText(from: image)
        
        print("📝 Extracted text: \(extractedText ?? "nil")")
        
        // Step 2: Parse the extracted text
        if let text = extractedText, !text.isEmpty {
            rawTransaction = OCRParser.parse(text: text)
            
            print(rawTransaction != nil ? "✅ Parsed result: Success" : "⚠️ OCR parsing failed")
        } else {
            print("⚠️ No text extracted from image")
        }
    }
    
    func extractText(from image: UIImage) async -> String? {
        guard let cgImage = image.cgImage else {
            print("❌ Failed to get CGImage")
            return nil
        }
        
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    print("❌ Vision error: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    print("❌ No observations found")
                    continuation.resume(returning: nil)
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                print("📄 Vision recognized \(observations.count) text blocks")
                continuation.resume(returning: recognizedText)
            }
            
            request.recognitionLevel = .accurate
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                print("❌ Failed to perform Vision request: \(error)")
                continuation.resume(returning: nil)
            }
        }
    }
    
    func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let ratio = max(size.width, size.height) / maxDimension
        
        guard ratio > 1 else { return image }
        
        let newSize = CGSize(
            width: size.width / ratio,
            height: size.height / ratio
        )
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
