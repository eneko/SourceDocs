//
//  MarkdownObject.swift
//  SourceDocsLib
//
//  Created by Eneko Alonso on 11/13/17.
//

import Foundation
import SourceKittenFramework
import MarkdownGenerator

struct MarkdownObject: SwiftDocDictionaryInitializable, MarkdownConvertible, MarkdownReportable {

    let dictionary: SwiftDocDictionary
    let options: MarkdownOptions

    let properties: [MarkdownVariable]
    let methods: [MarkdownMethod]

    var reportingChildren: [[MarkdownReportable]]? {
        [properties, methods]
    }

    init?(dictionary: SwiftDocDictionary) {
        fatalError("Not supported")
    }

    init?(dictionary: SwiftDocDictionary, options: MarkdownOptions) {
        guard dictionary.accessLevel >= options.minimumAccessLevel && dictionary.isKind([.struct, .class]) else {
            return nil
        }
        self.dictionary = dictionary
        self.options = options

        if let structure: [SwiftDocDictionary] = dictionary.get(.substructure) {
            properties = structure.compactMap { MarkdownVariable(dictionary: $0, options: options) }
            methods = structure.compactMap { MarkdownMethod(dictionary: $0, options: options) }
        } else {
            properties = []
            methods = []
        }
    }

    var elementType: String {
        if dictionary.isKind(.struct) {
            return "struct"
        }
        if dictionary.isKind(.class) {
            return "class"
        }
        return ""
    }

    var tableOfContents: String {
        var tableOfContents: [String] = []

        let propertyToc = self.properties.map { "  - `\($0.name)`" }.joined(separator: "\n")
        if propertyToc.isEmpty == false {
            tableOfContents.append("- [Properties](#properties)")
            tableOfContents.append(propertyToc)
        }

        let methodToc = self.methods.map { "  - `\($0.name)`" }.joined(separator: "\n")
        if methodToc.isEmpty == false {
            tableOfContents.append("- [Methods](#methods)")
            tableOfContents.append(methodToc)
        }

        if tableOfContents.isEmpty {
            return ""
        }

        return """
        **Contents**

        \(tableOfContents.joined(separator: "\n"))
        """
    }

    var markdown: String {
        let toc = options.tableOfContents ? tableOfContents : ""
        let properties = collectionOutput(title: "## Properties", collection: self.properties)
        let methods = collectionOutput(title: "## Methods", collection: self.methods)

        return """
        **\(elementType.uppercased())**

        # `\(name)`

        \(toc)

        \(declaration)

        \(comment)

        \(properties)

        \(methods)
        """
    }
}
