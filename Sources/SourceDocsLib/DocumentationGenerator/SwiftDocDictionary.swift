//
//  SwiftDocDictionary.swift
//  SourceDocsLib
//
//  Created by Eneko Alonso on 10/3/17.
//

import Foundation
import SourceKittenFramework
import MarkdownGenerator

typealias SwiftDocDictionary = [String: Any]

extension Dictionary where Key == String, Value == Any {
    func get<T>(_ key: SwiftDocKey) -> T? {
        return self[key.rawValue] as? T
    }

    var accessLevel: AccessLevel {
        let accessiblityKey = self["key.accessibility"] as? String
        return AccessLevel(accessiblityKey: accessiblityKey)
    }

    func isKind(_ kind: SwiftDeclarationKind) -> Bool {
        return SwiftDeclarationKind(rawValue: get(.kind) ?? "") == kind
    }

    func isKind(_ kinds: [SwiftDeclarationKind]) -> Bool {
        guard let value: String = get(.kind), let kind = SwiftDeclarationKind(rawValue: value) else {
            return false
        }
        return kinds.contains(kind)
    }
}

protocol MarkdownReportable: SwiftDocDictionaryInitializable {
    var reportingChildren: [[MarkdownReportable]]? { get }
}

extension MarkdownReportable {

    func report (whereAccessLevel accessLevel: AccessLevel) -> MarkdownReport {
        guard self.dictionary.accessLevel.priority >= accessLevel.priority else {
            return MarkdownReport(total: 0, processed: 0)
        }

        var report = MarkdownReport(total: 1, processed: self.isReporting ? 1 : 0)

        guard let children = self.reportingChildren else {
            return report
        }

        report = children.flatMap { $0 }.map {
            $0.report(whereAccessLevel: accessLevel)
        }.reduce(report, +)

        return report
    }
}

protocol SwiftDocDictionaryInitializable {
    var dictionary: SwiftDocDictionary { get }

    init?(dictionary: SwiftDocDictionary)
}

extension SwiftDocDictionaryInitializable {
    var name: String {
        let name = dictionary.get(.name) ?? "[NO NAME]"
        if dictionary.isKind([.struct, .class, .enum, .typealias]) {
            return (dictionary.parentNames + [name]).joined(separator: ".")
        } else {
            return name
        }
    }

    var comment: String {
        return dictionary.get(.documentationComment) ?? ""
    }

    var declaration: String {
        guard let declaration: String = dictionary.get(.parsedDeclaration) else {
            return ""
        }
        return MarkdownCodeBlock(code: declaration, style: .backticks(language: "swift")).markdown
    }

    func collectionOutput(title: String, collection: [MarkdownConvertible]) -> String {
        return collection.isEmpty ? "" : """
        \(title)
        \(collection.markdown)
        """
    }

    var isReporting: Bool {
        return self.dictionary[SwiftDocKey.documentationComment.rawValue] != nil
    }
}
