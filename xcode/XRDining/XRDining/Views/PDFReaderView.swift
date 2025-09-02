//
//  PDFReaderView.swift
//  XRDining
//
//  Created by Rick van Haasen on 25/08/2025.
//

// MARK: - Minimal PDFKit-backed SwiftUI view (no controls)

import SwiftUI
import RealityKit
import PDFKit

struct PDFReaderView: UIViewRepresentable { // visionOS bridges via UIKit representable
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let v = PDFView()
        v.autoScales = true
        v.displayMode = .singlePageContinuous
        v.displayDirection = .vertical
        v.backgroundColor = .clear
        v.document = PDFDocument(url: url)
        return v
    }
    
    func updateUIView(_ view: PDFView, context: Context) {
        // Swap the document if the URL changes
        if view.document?.documentURL != url {
            view.document = PDFDocument(url: url)
        }
    }
}
#Preview {
    PDFReaderView(url: Bundle.main.url(forResource: "factuur", withExtension: "pdf")!)
        .frame(width: 200, height: 350) // render size in points (texture resolution)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(8)
}
