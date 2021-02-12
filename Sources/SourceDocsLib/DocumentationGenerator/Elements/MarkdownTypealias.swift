//
//  MarkdownTypealias.swift
//  SourceDocsLib
//
//  Created by Eneko Alonso on 11/13/17.
//

import Foundation
import SourceKittenFramework
import MarkdownGenerator

struct MarkdownTypealias: SwiftDocDictionaryInitializable, MarkdownConvertible, MarkdownReportable {
    let dictionary: SwiftDocDictionary
    let options: MarkdownOptions

    init?(dictionary: SwiftDocDictionary) {
        fatalError("Not supported")
    }

    let reportingChildren: [[MarkdownReportable]]? = nil

    init?(dictionary: SwiftDocDictionary, options: MarkdownOptions) {
        guard dictionary.accessLevel >= options.minimumAccessLevel && dictionary.isKind([.typealias]) else {
            return nil
        }
        self.dictionary = dictionary
        self.options = options
    }

    var markdown: String {
        return """
        **TYPEALIAS**

        # `\(name)`

        \(declaration)

        \(comment)
        """
    }

}
