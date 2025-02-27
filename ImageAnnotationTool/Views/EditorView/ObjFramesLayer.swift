//
//  ObjFramesLayer.swift
//  ImageAnnotationTool
//
//  Created by Sergey on 10.06.2020.
//  Copyright © 2020 R2. All rights reserved.
//

import SwiftUI

struct ObjectFramesLayer: View {
    
    @EnvironmentObject var currentDoc: Document
    var pixelRatio: CGFloat
    
    @GestureState private var dragGestureState: DragGesture.Value? = nil
    
    private var newObjectFrame: ObjectFrame {
        ObjectFrame(dragGesureValue: dragGestureState!)
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .opacity(0)
                .contentShape(Rectangle())
                .gesture(dragGesture)
                .border(Color.yellow)
            
            // new object frame that currently in the adjust process
            if self.dragGestureState != nil && currentDoc.labelManager.selectedLabel != nil {
                ObjFrameView(width: self.newObjectFrame.width,
                             height: self.newObjectFrame.height,
                             position: self.newObjectFrame.position,
                             color: currentDoc.labelManager.selectedLabel!.color, caption: currentDoc.labelManager.selectedLabel?.text ?? "",
                             selected: true)
            }
            
            // object frames already existing in the model
            if self.currentDoc.currentImageInfo?.annotations != nil {
                ForEach(self.currentDoc.currentImageInfo!.annotations!, id: \.self) { annotation in
                    ObjFrameView(width: CGFloat(annotation.coordinates.width) / pixelRatio,
                                 height: CGFloat(annotation.coordinates.height) / pixelRatio,
                                 position: CGPoint(x: CGFloat(annotation.coordinates.x - annotation.coordinates.width / 2) / pixelRatio,
                                                   y: CGFloat(annotation.coordinates.y - annotation.coordinates.height / 2) / pixelRatio),
                                 color: annotation.label.color, caption: annotation.label.text,
                                 selected: false)
                        .contextMenu {
                            Button(action: {
                                self.currentDoc.currentImageInfo?.deleteObjAnnotation(annotation)
                                self.currentDoc.objectWillChange.send()
                            } ) { Text("Delete '\(annotation.label.text)'") }
                    }
                }
            }
            
        }

    }
    
    //MARK: - Gestures
    private struct ObjectFrame {
        let width: CGFloat
        let height: CGFloat
        let position: CGPoint
        
        init(dragGesureValue: DragGesture.Value) {
            width = (dragGesureValue.location.x - dragGesureValue.startLocation.x).magnitude
            height = (dragGesureValue.location.y - dragGesureValue.startLocation.y).magnitude
            position = CGPoint(x: dragGesureValue.startLocation.x,
                               y: dragGesureValue.startLocation.y)
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .local)
            .updating($dragGestureState) { currDrugState, dragGestureState, _ in
                dragGestureState = currDrugState
        }
        .onEnded { currDrugState in
            if let selectedLabel = self.currentDoc.labelManager.selectedLabel {
                let newObjectFrame = ObjectFrame(dragGesureValue: currDrugState)
                
                let coordinates = ObjectAnnotation.Coordinates(x: Int((newObjectFrame.position.x + newObjectFrame.width / 2) * pixelRatio),
                                                               y: Int((newObjectFrame.position.y + newObjectFrame.height / 2) * pixelRatio),
                                                               width: Int(newObjectFrame.width * pixelRatio),
                                                               height: Int(newObjectFrame.height * pixelRatio))
                
                let newAnnotation = ObjectAnnotation(label: selectedLabel, coordinates: coordinates)
                self.currentDoc.currentImageInfo?.addNewObjAnnotation(newAnnotation)
                self.currentDoc.objectWillChange.send()
            }

        }
    }

}
