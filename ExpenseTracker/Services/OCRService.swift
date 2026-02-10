import Vision
import UIKit

final class OCRService {

    func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRFailure.invalidImage
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage)

        try handler.perform([request])

        let observations = request.results ?? []

        let text = observations
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")

        return text
    }
}

enum OCRFailure: Error {
    case invalidImage
}
