//
//  MarkdownVariable.swift
//  SourceDocsLib
//
//  Created by Eneko Alonso on 11/13/17.
//

import Foundation
import SourceKittenFramework
import MarkdownGenerator

struct MarkdownVariable: SwiftDocDictionaryInitializable, MarkdownConvertible, MarkdownReportable {
    let dictionary: SwiftDocDictionary
    let options: MarkdownOptions

    let reportingChildren: [[MarkdownReportable]]? = nil

    init?(dictionary: SwiftDocDictionary) {
        fatalError("Not supported")
    }

    init?(dictionary: SwiftDocDictionary, options: MarkdownOptions) {
        let variables: [SwiftDeclarationKind] = [.varInstance, .varStatic]
        guard dictionary.accessLevel >= options.minimumAccessLevel && dictionary.isKind(variables) else {
            return nil
        }
        self.dictionary = dictionary
        self.options = options
    }

    var markdown: String {
        let details = """
        \(declaration)

        \(comment)
        """

        if options.collapsibleBlocks {
            return MarkdownCollapsibleSection(summary: "<code>\(name)</code>", details: details).markdown
        } else {
            return """
            ### `\(name)`

            \(details)
            """
        }
    }
}
