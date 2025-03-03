//
//  LabelView.swift
//  ImageAnnotationTool
//
//  Created by Sergey on 13.05.2020.
//  Copyright © 2020 R2. All rights reserved.
//

import SwiftUI

struct ObjFrameView: View {
    var width: CGFloat
    var height: CGFloat
    var position: CGPoint
    var color: Color
    var caption: String
    @State var selected: Bool
    
    var body: some View {
        Group {
            if selected {
                selectedLabel
            } else {
                notSelectedLabel
            }
        }
        .frame(width: width, height: height)
        .position(CGPoint(x: position.x + width / 2, y: position.y + height / 2))
        //.onTapGesture { self.$selected.wrappedValue.toggle() }
    }
    
    var selectedLabel: some View {
        Rectangle()
            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
            .foregroundColor(color)
            .contentShape(Rectangle())
            .overlay(alignment: .topLeading) {
                Text(caption)
                    .foregroundStyle(color)
                    .font(.caption)
            }
    }
    
    var notSelectedLabel: some View {
        Rectangle()
            .stroke(color, lineWidth: 1)
            .opacity(0.6)
            .contentShape(Rectangle())
            .overlay(alignment: .topLeading) {
                Text(caption)
                    .foregroundStyle(color)
                    .font(.caption)
            }
    }
}

struct LabelView_Previews: PreviewProvider {
    static var previews: some View {
        ObjFrameView(width: 100,
                     height: 50,
                     position: CGPoint(x: 100, y: 100),
                     color: .orange,
                     caption: "caption",
                     selected: false)
    }
}

