//
//  CourseView.swift
//  XRDining
//
//  Created by Rick van Haasen on 02/09/2025.
//

import SwiftUI
import RealityKit
import RealityKitContent

let starterMessage = """
line1
line2                
"""
struct CourseView: View {
    var url: URL
    var modelName: String
    
    var body: some View {
        
        VStackLayout(spacing: 30).depthAlignment(.back)  {
            PDFReaderView(url: url)
                //.frame(width: 300, height: 350)
            //Spacer()
            Model3D(named: modelName, bundle: realityKitContentBundle) { model in
                if let model = model.model {
                    model
                        //.resizable()
                        //.scaledToFit3D()
                }
            }
            //.frame(width: 300, height: 350)

            // Push the carousel to the front of the rectangular volume.
//            VStack(alignment: .leading, spacing: 12) {
//                Text("Starter")
//                    .font(.title2)
//                    .fontWeight(.semibold)
//
//                Text(starterMessage)
//                    .font(.body)
//                    .foregroundStyle(.secondary)
//            }
//            .padding()
//            .frame(width: 600)
//            .background(.regularMaterial) // glass effect
//            .clipShape(RoundedRectangle(cornerRadius: 20))
//            .glassBackgroundEffect() // visionOS glass effect
//            .shadow(radius: 10)
 
 
//            VStackLayout(spacing: 20).depthAlignment(.front) {
//                Spacer()
//            }
        }
    }
}

#Preview {
    let pdfUrl = Bundle.main.url(forResource: "factuur", withExtension: "pdf")!
    CourseView(url: pdfUrl, modelName: "gebakske")
        .frame(width: 300, height: 600)
}
