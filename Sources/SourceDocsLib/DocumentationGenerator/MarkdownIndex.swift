//
//  MarkdownIndex.swift
//  SourceDocsLib
//
//  Created by Eneko Alonso on 10/4/17.
//

import Foundation
import MarkdownGenerator
import Rainbow

struct MarkdownOptions {
    var collapsibleBlocks: Bool
    var tableOfContents: Bool
    var minimumAccessLevel: AccessLevel
}

class MarkdownIndex {
    var structs: [MarkdownObject] = []
    var classes: [MarkdownObject] = []
    var extensions: [MarkdownExtension] = []
    var enums: [MarkdownEnum] = []
    var protocols: [MarkdownProtocol] = []
    var typealiases: [MarkdownTypealias] = []
    var methods: [MarkdownMethod] = []

    func reset() {
        structs = []
        classes = []
        extensions = []
        enums = []
        protocols = []
        typealiases = []
        methods = []
    }

    func report(
        to docsPath: String,
        linkBeginningText: String,
        linkEndingText: String,
        options: DocumentOptions
    ) throws -> MarkdownReport {
        var report = MarkdownReport(total: 0, processed: 0)
        extensions = flattenedExtensions()

        fputs("Generating Markdown report...\n".green, stdout)
        report = protocols.map { $0.report(whereAccessLevel: options.minimumAccessLevel) }
            .reduce(report, +)

        report = structs.map { $0.report(whereAccessLevel: options.minimumAccessLevel) }
            .reduce(report, +)

        report = classes.map { $0.report(whereAccessLevel: options.minimumAccessLevel) }
            .reduce(report, +)

        report = enums.map { $0.report(whereAccessLevel: options.minimumAccessLevel) }
            .reduce(report, +)

        report = extensions.map { $0.report(whereAccessLevel: options.minimumAccessLevel) }
            .reduce(report, +)

        report = typealiases.map { $0.report(whereAccessLevel: options.minimumAccessLevel) }
            .reduce(report, +)

        report = methods.map { $0.report(whereAccessLevel: options.minimumAccessLevel) }
            .reduce(report, +)

        return report
    }

    func write(
        to docsPath: String,
        linkBeginningText: String,
        linkEndingText: String,
        options: DocumentOptions
    ) throws {
        extensions = flattenedExtensions()

        fputs("Generating Markdown documentation...\n".green, stdout)
        var content: [MarkdownConvertible] = [
            "# Reference Documentation"
        ]

        try content.append(writeAndIndexFiles(items: protocols, to: docsPath, collectionTitle: "Protocols",
                                              linkBeginningText: linkBeginningText,
                                              linkEndingText: linkEndingText))
        try content.append(writeAndIndexFiles(items: structs, to: docsPath, collectionTitle: "Structs",
                                              linkBeginningText: linkBeginningText,
                                              linkEndingText: linkEndingText))
        try content.append(writeAndIndexFiles(items: classes, to: docsPath, collectionTitle: "Classes",
                                              linkBeginningText: linkBeginningText,
                                              linkEndingText: linkEndingText))
        try content.append(writeAndIndexFiles(items: enums, to: docsPath, collectionTitle: "Enums",
                                              linkBeginningText: linkBeginningText,
                                              linkEndingText: linkEndingText))
        try content.append(writeAndIndexFiles(items: extensions, to: docsPath, collectionTitle: "Extensions",
                                              linkBeginningText: linkBeginningText,
                                              linkEndingText: linkEndingText))
        try content.append(writeAndIndexFiles(items: typealiases, to: docsPath, collectionTitle: "Typealiases",
                                              linkBeginningText: linkBeginningText,
                                              linkEndingText: linkEndingText))
        try content.append(writeAndIndexFiles(items: methods, to: docsPath, collectionTitle: "Methods",
                                              linkBeginningText: linkBeginningText,
                                              linkEndingText: linkEndingText))

        let footer = DocumentationGenerator.generateFooter(reproducibleDocs: options.reproducibleDocs)
        content.append(footer)

        try writeFile(file: MarkdownFile(filename: "README", basePath: docsPath, content: content))
    }

    func writeAndIndexFiles(items: [MarkdownConvertible & SwiftDocDictionaryInitializable],
                            to docsPath: String, collectionTitle: String,
                            linkBeginningText: String,
                            linkEndingText: String) throws -> [MarkdownConvertible] {
        if items.isEmpty {
            return []
        }

        // Make and write files
        let files = makeFiles(with: items, basePath: "\(docsPath)/\(collectionTitle.lowercased())")
        try files.forEach { try writeFile(file: $0) }

        // Make links for index
        let links: [MarkdownLink] = files.map {
            let url = "\(linkBeginningText)\(collectionTitle.lowercased())/\($0.filename)\(linkEndingText)"
            return MarkdownLink(text: $0.filename, url: url)
        }
        return [
            "## \(collectionTitle)",
            MarkdownList(items: links.sorted { $0.text < $1.text })
        ]
    }

    func writeFile(file: MarkdownFile) throws {
        fputs("  Writing documentation file: \(file.filePath)", stdout)
        do {
            try file.write()
            fputs(" ✔\n".green, stdout)
        } catch let error {
            fputs(" ❌\n", stdout)
            throw error
        }
    }

    func makeFiles(with items: [MarkdownConvertible & SwiftDocDictionaryInitializable],
                   basePath: String) -> [MarkdownFile] {
        let illegal = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        return items.map { item in
            let filename = item.name.components(separatedBy: illegal).joined(separator: "_")
            return MarkdownFile(filename: filename, basePath: basePath, content: [item])
        }
    }

    /// While other types can only have one declaration within a Swift module,
    /// there can be multiple extensions for the same type.
    func flattenedExtensions() -> [MarkdownExtension] {
        let extensionsByType = zip(extensions.map { $0.name }, extensions)
        let groupedByType = Dictionary(extensionsByType) { existing, new -> MarkdownExtension in
            var merged = existing
            merged.methods += new.methods
            merged.properties += new.properties
            return merged
        }
        return Array(groupedByType.values)
    }
}
