import Foundation
import SourceKittenFramework

public final class ReportGenerator {

    var options: DocumentOptions
    let markdownIndex: MarkdownIndex

    public init(options: DocumentOptions) {
        self.options = options
        self.markdownIndex = MarkdownIndex()
    }

    public func run() throws -> MarkdownReport {
        let report: MarkdownReport
        markdownIndex.reset()

        do {
            if options.allModules {
                options.includeModuleNameInPath = true
                try PackageLoader.resolveDependencies(at: options.inputFolder)
                let packageDump = try PackageLoader.loadPackageDump(from: options.inputFolder)
                var reports = [MarkdownReport]()
                for target in packageDump.targets where target.type == .regular {
                    let docs = try parseSPMModule(moduleName: target.name, path: options.inputFolder)
                    reports.append(
                        try generateReport(docs: docs, module: target.name, options: options)
                    )
                }
                report = reports.reduce(MarkdownReport(total: 0, processed: 0), +)
            } else if let module = options.spmModule {
                let docs = try parseSPMModule(moduleName: module, path: options.inputFolder)
                report = try generateReport(docs: docs, module: module, options: options)
            } else if let module = options.moduleName {
                let docs = try parseSwiftModule(moduleName: module, args: options.xcodeArguments,
                                                path: options.inputFolder)
                report = try generateReport(docs: docs, module: module, options: options)
            } else {
                let docs = try parseXcodeProject(args: options.xcodeArguments, path: options.inputFolder)
                report = try generateReport(docs: docs, module: "", options: options)
            }
        } catch let error as SourceDocsError {
            throw error
        } catch let error {
            throw SourceDocsError.internalError(message: error.localizedDescription)
        }
        return report
    }

    private func parseSPMModule(moduleName: String, path: String) throws -> [SwiftDocs] {
        fputs("Processing SwiftPM module \(moduleName)...\n", stdout)
        guard let docs = Module(spmName: moduleName, inPath: path)?.docs else {
            let message = "Error: Failed to generate documentation for SwiftPM module '\(moduleName)'."
            throw SourceDocsError.internalError(message: message)
        }
        return docs
    }

    private func parseSwiftModule(moduleName: String, args: [String], path: String) throws -> [SwiftDocs] {
        fputs("Processing Swift module \(moduleName)...\n", stdout)
        guard let docs = Module(xcodeBuildArguments: args, name: moduleName, inPath: path)?.docs else {
            let message = "Error: Failed to generate documentation for module '\(moduleName)'."
            throw SourceDocsError.internalError(message: message)
        }
        return docs
    }

    private func parseXcodeProject(args: [String], path: String) throws -> [SwiftDocs] {
        fputs("Processing Xcode project with arguments \(args)...\n", stdout)
        guard let docs = Module(xcodeBuildArguments: args, name: nil, inPath: path)?.docs else {
            throw SourceDocsError.internalError(message: "Error: Failed to generate documentation.")
        }
        return docs
    }

    private func generateReport(docs: [SwiftDocs], module: String, options: DocumentOptions) throws -> MarkdownReport {
        let docsPath = options.includeModuleNameInPath ? "\(options.outputFolder)/\(module)" : options.outputFolder
        if options.clean {
            try DocumentationEraser(docsPath: docsPath).run()
        }
        process(docs: docs)
        let report = try markdownIndex.report(to: docsPath,
                                              linkBeginningText: options.linkBeginningText,
                                              linkEndingText: options.linkEndingText,
                                              options: options)
        markdownIndex.reset()
        return report
    }

    private func process(docs: [SwiftDocs]) {
        let dictionaries = docs.compactMap { $0.docsDictionary.bridge() as? SwiftDocDictionary }
        process(dictionaries: dictionaries)
    }

    private func process(dictionaries: [SwiftDocDictionary]) {
        dictionaries.forEach { process(dictionary: $0) }
    }

    private func process(dictionary: SwiftDocDictionary) {
        let markdownOptions = MarkdownOptions(collapsibleBlocks: options.collapsibleBlocks,
                                              tableOfContents: options.tableOfContents,
                                              minimumAccessLevel: options.minimumAccessLevel)

        if let value: String = dictionary.get(.kind), let kind = SwiftDeclarationKind(rawValue: value) {
            if kind == .struct, let item = MarkdownObject(dictionary: dictionary, options: markdownOptions) {
                markdownIndex.structs.append(item)
            } else if kind == .class, let item = MarkdownObject(dictionary: dictionary, options: markdownOptions) {
                markdownIndex.classes.append(item)
            } else if let item = MarkdownExtension(dictionary: dictionary, options: markdownOptions) {
                markdownIndex.extensions.append(item)
            } else if let item = MarkdownEnum(dictionary: dictionary, options: markdownOptions) {
                markdownIndex.enums.append(item)
            } else if let item = MarkdownProtocol(dictionary: dictionary, options: markdownOptions) {
                markdownIndex.protocols.append(item)
            } else if let item = MarkdownTypealias(dictionary: dictionary, options: markdownOptions) {
                markdownIndex.typealiases.append(item)
            } else if kind == .functionFree,
                let item = MarkdownMethod(dictionary: dictionary, options: markdownOptions) {
                markdownIndex.methods.append(item)
            }
        }

        if let substructure = dictionary[SwiftDocKey.substructure.rawValue] as? [SwiftDocDictionary] {
            let substructureWithParent: [SwiftDocDictionary]
            if let parentName: String = dictionary.get(.name) {
                substructureWithParent = substructure.map {
                    var dict = $0
                    dict.parentNames.append(parentName)
                    return dict
                }
            } else {
                substructureWithParent = substructure
            }

            process(dictionaries: substructureWithParent)
        }
    }
}
