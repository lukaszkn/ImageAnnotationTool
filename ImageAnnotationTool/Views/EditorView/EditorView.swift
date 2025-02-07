//
//  ImageView.swift
//  ImageAnnotationTool
//
//  Created by Sergey on 11.05.2020.
//  Copyright © 2020 R2. All rights reserved.
//

import SwiftUI

struct EditorView: View {
    
    @EnvironmentObject var currentDoc: Document
    var zoom: CGFloat
    var pixelSize: CGSize
    
    var body: some View {
        imageView.overlay {
            GeometryReader { geometry in
                ObjectFramesLayer(pixelRatio: pixelSize.width / geometry.size.width)
            }
        }
    }
    
    private var imageView: some View {
        Image(nsImage: self.currentDoc.imageManager.currentNSImage)
            .resizable()
            .scaledToFit()
            .border(Color.blue)
    }
}

struct ImageView_Previews: PreviewProvider {
    static var previews: some View {
        EditorView(zoom: 0.2,
                   pixelSize: CGSize(width: 400, height: 300))
            .environmentObject(Document())
    }
}
