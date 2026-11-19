//
//  Document.swift
//  ImageAnnotationTool
//
//  Created by Сергей on 20.02.2020.
//  Copyright © 2020 R2. All rights reserved.
//

import Cocoa
import SwiftUI

class Document: NSDocument, ObservableObject {
    
    lazy var imageManager = ImageManager(doc: self)
    lazy var labelManager = LabelManager(doc: self)
    
    private(set) var imagesInfo: [String: ImageInfo] = [:]
    var currentImageInfo: ImageInfo? {
        if let id = imageManager.currentImage?.id {
            return imagesInfo[id]
        } else {
            return nil
        }
    }
    
    func addImagesInfo(names: Set<String>) {
        _ = names.map { imagesInfo[$0] = ImageInfo(imagefilename: $0) }
    }
    
    func delImagesInfo(names: Set<String>) {
        _ = names.map { imagesInfo.removeValue(forKey: $0) }
    }
    
    static let labelManagerKey = CodingUserInfoKey(rawValue: "labelManager")!
    
    //MARK: - Initializers
    override init() {
        super.init()
    }
    
    override class var autosavesInPlace: Bool {
        return true
    }
    
    override func makeWindowControllers() {
        // Create the SwiftUI view that provides the window contents.
        let contentView = MainView().environmentObject(self)

        // Create the window and set the content view.
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.contentView = NSHostingView(rootView: contentView)
        let windowController = NSWindowController(window: window)
        self.addWindowController(windowController)
    }
    
    //MARK: - JSON
    override func data(ofType typeName: String) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(Array(imagesInfo.values))
    }
    
    override func writeSafely(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType) throws {
        try super.writeSafely(to: url, ofType: typeName, for: saveOperation)
        try LabelFile.write(names: labelManager.labels.map(\.text), nextTo: url)
        imageManager.saveTxtLabels()
    }

    override func read(from url: URL, ofType typeName: String) throws {
        let loadedLabels = LabelManager(doc: nil)
        for name in try LabelFile.readNames(nextTo: url) {
            _ = loadedLabels.addLabel(name)
        }

        let decoder = JSONDecoder()
        decoder.userInfo[Self.labelManagerKey] = loadedLabels
        let loadedImages = try decoder.decode([ImageInfo].self, from: Data(contentsOf: url))

        loadedLabels.doc = self
        labelManager = loadedLabels
        imagesInfo = Dictionary(loadedImages.map { ($0.image, $0) }, uniquingKeysWith: { _, latest in latest })
        imageManager.checkAndUpdateImagesInfo(documentURL: url, removeMissingImageInfo: false)
    }
    
}

