//
//  LabelManager.swift
//  ImageAnnotationTool
//
//  Created by Sergey on 05.05.2020.
//  Copyright © 2020 R2. All rights reserved.
//

import Foundation
import SwiftUI
import Yams

final class LabelManager {
    weak var doc: Document?
    private(set) var labels = [Label]() {
        didSet {
            doc?.objectWillChange.send()
        }
    }
    var selectedLabel: Label? {
        didSet {
            doc?.objectWillChange.send()
        }
    }
    
    private(set) var colorManager = LabelColorManager()
    
    func addLabel(_ initText: String? = nil) -> Label {
        let text = initText ?? nextLabelName()
        
        for label in labels {
            if label.text == text {
                return label
            }
        }
        
        let newLabel = Label(text: text, color: colorManager.getColor(text: text))
        addLabel(label: newLabel)
        return newLabel
    }

    private func nextLabelName() -> String {
        var number = labels.count + 1
        while labels.contains(where: { $0.text == "New label \(number)" }) {
            number += 1
        }
        return "New label \(number)"
    }
    
    func addLabel(label: Label) {
        labels.append(label)
        selectedLabel = label
        doc?.updateChangeCount(.changeDone)
    }

    func renameLabel(_ label: Label, to text: String) {
        guard !labels.contains(where: { $0.text == text }) else { return }
        doc?.objectWillChange.send()
        label.text = text
        doc?.updateChangeCount(.changeDone)
    }
    
    func deleteLabel(_ label: Label? = nil) {
        guard let label = label ?? selectedLabel, let index = labels.firstIndex(of: label) else { return }
        let isUsed = doc?.imagesInfo.values.contains { image in
            image.annotations?.contains { $0.label == label } == true
        }
        guard isUsed != true else { return }
        labels.remove(at: index)
        if selectedLabel == label {
            selectedLabel = nil
        }
        doc?.updateChangeCount(.changeDone)
    }
    
    subscript(i: Int) -> Label {
        get {
            self.labels[i]
        }
        set {
            self.labels[i] = newValue
        }
    }
    
    init(doc: Document?) {
        self.doc = doc
    }
}

struct LabelFile: Decodable {
    private enum CodingKeys: String, CodingKey {
        case names
    }

    let names: [String]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard container.contains(.names), try !container.decodeNil(forKey: .names) else {
            names = []
            return
        }
        if let sequence = try? container.decode([String].self, forKey: .names) {
            names = sequence
        } else {
            let mapping = try container.decode([Int: String].self, forKey: .names)
            names = mapping.sorted { $0.key < $1.key }.map(\.value)
        }
    }

    static func readNames(nextTo documentURL: URL) throws -> [String] {
        let url = documentURL.deletingPathExtension().appendingPathExtension("yaml")
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return []
        }
        return try YAMLDecoder().decode(Self.self, from: data).names
    }

    static func write(names: [String], nextTo documentURL: URL) throws {
        let classes = Node(names.enumerated().map { index, name in
            (Node(String(index)), Node(name, .implicit, .doubleQuoted))
        })
        let dataset = Node([
            (Node("train"), Node("DataSetFolder/images/train")),
            (Node("val"), Node("DataSetFolder/images/val")),
            (Node("names"), classes)
        ])
        let yaml = try Yams.serialize(node: dataset, indent: 4)
        let url = documentURL.deletingPathExtension().appendingPathExtension("yaml")
        try yaml.write(to: url, atomically: true, encoding: .utf8)
    }
}
