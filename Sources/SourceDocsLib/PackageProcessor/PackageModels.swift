//
//  PackageModels.swift
//
//
//  Created by Eneko Alonso on 5/5/20.
//

import Foundation
import PackageModel

// MARK: - Package Dump (swift package dump-package)

struct PackageDump: Codable {
    let name: String
    let platforms: [SimplePlatform]
    let products: [ProductDescription]
    let targets: [TargetDescription]
    let dependencies: [PackageDependencyDescription]
    let toolsVersion: ToolsVersion
    let swiftLanguageVersions: [SwiftLanguageVersion]?
}

struct SimplePlatform: Codable {
    let platformName: String
    let version: String?
}

// MARK: - Package Dependencies (swift package show-dependencies --format json)

struct PackageDependency: Codable {
    let name: String
    let url: String
    let version: String
    let dependencies: [PackageDependency]
}

// MARK: Helper extensions for PackageModel

extension ProductType {
    var label: String {
        switch description {
        case "automatic":
            return "Library (automatic)"
        case "dynamic":
            return "Library (dynamic)"
        case "static":
            return "Library (static)"
        default:
            return description.capitalized
        }
    }
}

extension TargetDescription.Dependency {
    var name: String {
        switch self {
        case let .byName(name, _):
            return name
        case let .product(name, _, _):
            return name
        case let .target(name, _):
            return name
        }
    }
}
